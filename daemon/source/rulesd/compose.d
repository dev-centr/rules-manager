module rulesd.compose;

import std.exception : enforce;
import std.file : exists, mkdirRecurse, readText, write;
import std.path : buildPath, dirName;
import std.string : strip;

import rulesd.config : RulesConfig, resolveProfileId;
import rulesd.markers : composeDocument, fillConstants, parseComposed;

struct ComposeResult
{
    string composedPath;
    string profileId;
    string globalPath;
    string overlayPath;
}

string[string] loadProfileConstants(string repoPath, string profileId)
{
    import std.regex : matchAll, regex;

    string[string] constants;
    auto path = buildPath(repoPath, "profiles", profileId ~ ".md");
    if (!exists(path))
        return constants;

    auto text = readText(path);
    // CODE_ROOT = value   or   CODE_ROOT = `value`
    auto re = regex(`(?m)^\s*([A-Z_]+)\s*=\s*([^\n#]+)`);
    foreach (m; matchAll(text, re))
    {
        auto v = m[2].strip;
        if (v.length >= 2 && v[0] == '`' && v[$ - 1] == '`')
            v = v[1 .. $ - 1];
        constants[m[1]] = v.strip;
    }
    return constants;
}

string readOverlay(string repoPath, string profileId)
{
    auto path = buildPath(repoPath, "profiles", profileId ~ ".overlay.md");
    if (!exists(path))
        return "- (no machine overlay yet)";
    return readText(path);
}

ComposeResult composeOnce(RulesConfig cfg, string hostname)
{
    auto profileId = resolveProfileId(cfg, hostname);
    auto rulesPath = buildPath(cfg.rulesRepoPath, "RULES.md");
    enforce(exists(rulesPath), "RULES.md missing in rules repo: " ~ rulesPath);

    auto constants = loadProfileConstants(cfg.rulesRepoPath, profileId);
    if ("CODE_ROOT" !in constants && cfg.codeRoot.length)
        constants["CODE_ROOT"] = cfg.codeRoot;

    auto globalBody = fillConstants(readText(rulesPath), constants);
    auto machineBody = readOverlay(cfg.rulesRepoPath, profileId);
    auto doc = composeDocument(globalBody, machineBody);

    mkdirRecurse(dirName(cfg.composedPath));
    write(cfg.composedPath, doc);

    ComposeResult r;
    r.composedPath = cfg.composedPath;
    r.profileId = profileId;
    r.globalPath = rulesPath;
    r.overlayPath = buildPath(cfg.rulesRepoPath, "profiles", profileId ~ ".overlay.md");
    return r;
}

void patchGlobalFromComposed(RulesConfig cfg, string composedText)
{
    auto sections = parseComposed(composedText);
    enforce(exists(cfg.rulesRepoPath), "rules repo path missing");
    auto rulesPath = buildPath(cfg.rulesRepoPath, "RULES.md");
    write(rulesPath, sections.globalBody ~ "\n");
}

void patchMachineFromComposed(RulesConfig cfg, string hostname, string composedText)
{
    auto sections = parseComposed(composedText);
    auto profileId = resolveProfileId(cfg, hostname);
    auto overlayPath = buildPath(cfg.rulesRepoPath, "profiles", profileId ~ ".overlay.md");
    mkdirRecurse(dirName(overlayPath));
    write(overlayPath, sections.machineBody ~ "\n");
}
