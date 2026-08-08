module app;

import core.thread : Thread;
import std.file : exists;
import std.getopt;
import std.path : buildPath;
import std.stdio;
import std.string : strip;

import rulesd.compose : composeOnce;
import rulesd.config : RulesConfig, defaultConfig, loadConfig, saveConfig;
import rulesd.ipc : serveIpc;
import rulesd.watch : runWatchLoop;

__gshared bool gStop = false;

version (Windows)
{
    extern (Windows) int SetConsoleCtrlHandler(bool function(uint), bool);
    extern (Windows) bool consoleHandler(uint)
    {
        gStop = true;
        return true;
    }
}

string detectHostname()
{
    import std.process : environment, executeShell;

    version (Windows)
    {
        auto h = environment.get("COMPUTERNAME");
        if (h.length)
            return h;
    }
    else
    {
        auto h = environment.get("HOSTNAME");
        if (h.length)
            return h;
        auto r = executeShell("hostname");
        if (r.status == 0)
            return r.output.strip;
    }
    return "unknown";
}

string defaultCodeRoot()
{
    import std.process : environment;
    import std.path : expandTilde;

    auto e = environment.get("CODE_ROOT");
    if (e.length)
        return e;
    version (Windows)
        return `C:\code`;
    else
        return expandTilde("~/code");
}

void pickRulesRepo(ref RulesConfig c, string codeRoot)
{
    auto orgClone = buildPath(codeRoot, "github.com", "dev-centr", "agent-rules");
    if (exists(orgClone))
        c.rulesRepoPath = orgClone;
}

enum rulesdVersion = "0.1.0";

int main(string[] args)
{
    string configPath;
    bool doCompose;
    bool doServe;
    bool writeDefaultConfig;
    bool showVersion;
    bool debugDump;
    string codeRoot = defaultCodeRoot();

    auto helpInfo = getopt(args,
        "config|c", "Path to rules-manager config JSON", &configPath,
        "compose", "Compose once and exit (unless --serve)", &doCompose,
        "serve", "Run watcher + IPC server", &doServe,
        "write-config", "Write a default config file and exit", &writeDefaultConfig,
        "code-root", "CODE_ROOT override", &codeRoot,
        "version", "Print version and exit", &showVersion,
        "debug-dump", "Print redacted runtime dump and exit", &debugDump,
    );

    if (helpInfo.helpWanted)
    {
        defaultGetoptPrinter("rulesd — agent-rules compose & watch daemon\n", helpInfo.options);
        return 0;
    }

    if (showVersion)
    {
        writeln("rulesd ", rulesdVersion);
        return 0;
    }

    if (!configPath.length)
        configPath = buildPath(codeRoot, "rules-manager.config.json");

    if (writeDefaultConfig)
    {
        auto c = defaultConfig(codeRoot);
        pickRulesRepo(c, codeRoot);
        saveConfig(configPath, c);
        writeln("wrote ", configPath);
        return 0;
    }

    RulesConfig cfg;
    if (exists(configPath))
        cfg = loadConfig(configPath);
    else
    {
        cfg = defaultConfig(codeRoot);
        pickRulesRepo(cfg, codeRoot);
        stderr.writeln("no config at ", configPath, " — using defaults; pass --write-config to persist");
    }

    auto hostname = detectHostname();

    if (debugDump)
    {
        import rulesd.config : resolveProfileId;
        import std.json;

        auto dump = JSONValue([
            "version": JSONValue(rulesdVersion),
            "hostname": JSONValue(hostname),
            "profile": JSONValue(resolveProfileId(cfg, hostname)),
            "code_root": JSONValue(cfg.codeRoot),
            "rules_repo_path": JSONValue(cfg.rulesRepoPath),
            "composed_path": JSONValue(cfg.composedPath),
            "ipc_port": JSONValue(cfg.ipcPort),
            "debounce_ms": JSONValue(cfg.debounceMs),
            "note": JSONValue("paths are local; no secrets expected in this dump"),
        ]);
        writeln(dump.toPrettyString);
        return 0;
    }

    writeln("rulesd ", rulesdVersion, " host=", hostname, " repo=", cfg.rulesRepoPath);

    // Default with no flags: serve
    if (!doCompose && !doServe)
        doServe = true;

    if (doCompose || !exists(cfg.composedPath))
    {
        auto r = composeOnce(cfg, hostname);
        writeln("composed ", r.composedPath, " profile=", r.profileId);
    }

    if (!doServe)
        return 0;

    version (Windows)
        SetConsoleCtrlHandler(&consoleHandler, true);

    bool stop()
    {
        return gStop;
    }

    auto watchThread = new Thread({
        runWatchLoop(cfg, hostname, &stop);
    });
    watchThread.isDaemon = true;
    watchThread.start();

    serveIpc(cfg, hostname, cfg.ipcPort, &stop);
    gStop = true;
    watchThread.join();
    return 0;
}
