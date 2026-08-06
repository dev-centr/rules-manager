module rulesd.config;

import std.conv : to;
import std.exception : enforce;
import std.file : exists, readText, write;
import std.json;
import std.path : buildPath, dirName, expandTilde;
import std.stdio : stderr;
import std.string : strip;

struct RulesConfig
{
    string rulesRepoPath;
    string composedPath;
    string codeRoot;
    string activeProfile = "laptop";
    string[string] hostnameMap; // hostname -> profile id
    uint debounceMs = 500;
    ushort ipcPort = 17355;
}

RulesConfig defaultConfig(string codeRoot)
{
    RulesConfig c;
    c.codeRoot = codeRoot;
    c.composedPath = buildPath(codeRoot, "agent-rules.composed.md");
    c.rulesRepoPath = buildPath(codeRoot, "github.com", "AMDphreak", "agent-rules");
    c.hostnameMap = [
        "RJ-WIN-Laptop": "laptop",
        "RJ-WIN-Desktop": "desktop",
    ];
    return c;
}

RulesConfig loadConfig(string path)
{
    enforce(exists(path), "config not found: " ~ path);
    auto j = parseJSON(readText(path));
    RulesConfig c;
    c.rulesRepoPath = j["rules_repo_path"].str;
    c.composedPath = j["composed_path"].str;
    c.codeRoot = j["code_root"].str;
    if ("active_profile" in j)
        c.activeProfile = j["active_profile"].str;
    if ("debounce_ms" in j)
        c.debounceMs = j["debounce_ms"].integer.to!uint;
    if ("ipc_port" in j)
        c.ipcPort = cast(ushort) j["ipc_port"].integer;
    if ("hostname_map" in j)
    {
        foreach (string host, ref val; j["hostname_map"].object)
            c.hostnameMap[host] = val.str;
    }
    return c;
}

void saveConfig(string path, RulesConfig c)
{
    import std.file : mkdirRecurse;

    mkdirRecurse(dirName(path));
    JSONValue map = JSONValue((JSONValue[string]).init);
    foreach (k, v; c.hostnameMap)
        map[k] = JSONValue(v);

    auto root = JSONValue([
        "rules_repo_path": JSONValue(c.rulesRepoPath),
        "composed_path": JSONValue(c.composedPath),
        "code_root": JSONValue(c.codeRoot),
        "active_profile": JSONValue(c.activeProfile),
        "debounce_ms": JSONValue(c.debounceMs),
        "ipc_port": JSONValue(c.ipcPort),
        "hostname_map": map,
    ]);
    write(path, root.toPrettyString);
}

string resolveProfileId(RulesConfig c, string hostname)
{
    if (hostname in c.hostnameMap)
        return c.hostnameMap[hostname];
    return c.activeProfile;
}
