module rulesd.watch;

import core.thread : Thread;
import core.time : msecs;
import std.datetime.systime : Clock, SysTime;
import std.file : exists, getSize, timeLastModified;
import std.stdio : stderr;

import rulesd.compose : composeOnce, patchGlobalFromComposed, patchMachineFromComposed;
import rulesd.config : RulesConfig, resolveProfileId;
import rulesd.markers : parseComposed;
import std.file : readText;
import std.path : buildPath;

struct WatchState
{
    bool dirty;
    string lastError;
    string profileId;
    string status = "idle";
}

__gshared WatchState gWatchState;

private struct Stamp
{
    SysTime mtime;
    ulong size;
}

private Stamp stampOf(string path)
{
    Stamp s;
    if (!exists(path))
        return s;
    s.mtime = timeLastModified(path);
    s.size = getSize(path);
    return s;
}

private bool changed(Stamp a, Stamp b)
{
    return a.mtime != b.mtime || a.size != b.size;
}

/** Blocking watch loop (call from a dedicated thread or main). */
void runWatchLoop(RulesConfig cfg, string hostname, bool delegate() shouldStop)
{
    auto profileId = resolveProfileId(cfg, hostname);
    gWatchState.profileId = profileId;

    auto rulesPath = buildPath(cfg.rulesRepoPath, "RULES.md");
    auto overlayPath = buildPath(cfg.rulesRepoPath, "profiles", profileId ~ ".overlay.md");

    Stamp lastRules = stampOf(rulesPath);
    Stamp lastOverlay = stampOf(overlayPath);
    Stamp lastComposed = stampOf(cfg.composedPath);

    // Ignore self-writes briefly
    bool ignoreComposedOnce = false;
    bool ignoreRulesOnce = false;
    bool ignoreOverlayOnce = false;

    while (!shouldStop())
    {
        Thread.sleep(cfg.debounceMs.msecs);
        try
        {
            auto r = stampOf(rulesPath);
            auto o = stampOf(overlayPath);
            auto c = stampOf(cfg.composedPath);

            if (changed(r, lastRules))
            {
                lastRules = r;
                if (ignoreRulesOnce)
                {
                    ignoreRulesOnce = false;
                }
                else
                {
                    gWatchState.status = "recomposing-from-rules";
                    auto result = composeOnce(cfg, hostname);
                    lastComposed = stampOf(result.composedPath);
                    ignoreComposedOnce = true;
                    gWatchState.status = "idle";
                    gWatchState.dirty = false;
                    gWatchState.lastError = null;
                }
            }

            if (changed(o, lastOverlay))
            {
                lastOverlay = o;
                if (ignoreOverlayOnce)
                {
                    ignoreOverlayOnce = false;
                }
                else
                {
                    gWatchState.status = "recomposing-from-overlay";
                    auto result = composeOnce(cfg, hostname);
                    lastComposed = stampOf(result.composedPath);
                    ignoreComposedOnce = true;
                    gWatchState.status = "idle";
                }
            }

            if (changed(c, lastComposed))
            {
                lastComposed = c;
                if (ignoreComposedOnce)
                {
                    ignoreComposedOnce = false;
                }
                else if (exists(cfg.composedPath))
                {
                    auto text = readText(cfg.composedPath);
                    auto sections = parseComposed(text);
                    if (!sections.hasMarkers)
                    {
                        gWatchState.lastError = "composed file missing markers";
                        gWatchState.status = "error";
                        continue;
                    }
                    gWatchState.status = "patching-sources";
                    patchGlobalFromComposed(cfg, text);
                    patchMachineFromComposed(cfg, hostname, text);
                    lastRules = stampOf(rulesPath);
                    lastOverlay = stampOf(overlayPath);
                    ignoreRulesOnce = true;
                    ignoreOverlayOnce = true;
                    gWatchState.dirty = true;
                    gWatchState.status = "idle";
                    gWatchState.lastError = null;
                }
            }
        }
        catch (Exception e)
        {
            gWatchState.lastError = e.msg;
            gWatchState.status = "error";
            stderr.writeln("rulesd watch error: ", e.msg);
        }
    }
}
