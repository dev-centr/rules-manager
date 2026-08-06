module rulesd.ipc;

import core.thread : Thread;
import core.time : msecs;
import std.array : appender, split;
import std.conv : to;
import std.json;
import std.socket;
import std.stdio : stderr;
import std.string : startsWith;

import rulesd.compose : composeOnce;
import rulesd.config : RulesConfig;
import rulesd.watch : gWatchState;

/**
 * Minimal HTTP/1.1 JSON API on 127.0.0.1.
 * GET  /health
 * GET  /status
 * POST /compose  (also GET)
 */
void serveIpc(RulesConfig cfg, string hostname, ushort port, bool delegate() shouldStop)
{
    auto addr = new InternetAddress("127.0.0.1", port);
    auto listener = new TcpSocket();
    scope (exit)
        listener.close();

    listener.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 1);
    listener.bind(addr);
    listener.listen(8);
    listener.blocking = true;
    stderr.writeln("rulesd IPC listening on http://127.0.0.1:", port);

    while (!shouldStop())
    {
        // Timed accept so we can honor shouldStop
        auto set = new SocketSet();
        set.add(listener);
        auto n = Socket.select(set, null, null, 500.msecs);
        if (n <= 0)
            continue;

        Socket client;
        try
            client = listener.accept();
        catch (SocketAcceptException e)
        {
            stderr.writeln("ipc accept: ", e.msg);
            continue;
        }
        if (client is null)
            continue;

        try
            handleClient(client, cfg, hostname);
        catch (Exception e)
            stderr.writeln("ipc handle: ", e.msg);
        finally
            client.close();
    }
}

private void handleClient(Socket client, RulesConfig cfg, string hostname)
{
    client.blocking = true;
    char[8192] buf;
    auto n = client.receive(buf[]);
    if (n <= 0)
        return;
    auto req = buf[0 .. n].idup;
    auto firstLine = req.split("\r\n")[0];
    string method = "GET";
    string path = "/";
    {
        auto parts = firstLine.split(" ");
        if (parts.length >= 2)
        {
            method = parts[0];
            path = parts[1];
        }
    }

    JSONValue body;
    int code = 200;
    try
    {
        if (path.startsWith("/health"))
        {
            body = JSONValue(["ok": JSONValue(true), "service": JSONValue("rulesd")]);
        }
        else if (path.startsWith("/status"))
        {
            body = JSONValue([
                "status": JSONValue(gWatchState.status),
                "dirty": JSONValue(gWatchState.dirty),
                "profile": JSONValue(gWatchState.profileId),
                "error": JSONValue(gWatchState.lastError.length ? gWatchState.lastError : ""),
                "rules_repo": JSONValue(cfg.rulesRepoPath),
                "composed": JSONValue(cfg.composedPath),
            ]);
        }
        else if (path.startsWith("/compose") && (method == "POST" || method == "GET"))
        {
            auto result = composeOnce(cfg, hostname);
            body = JSONValue([
                "ok": JSONValue(true),
                "composed": JSONValue(result.composedPath),
                "profile": JSONValue(result.profileId),
            ]);
            gWatchState.profileId = result.profileId;
            gWatchState.status = "idle";
            gWatchState.lastError = null;
        }
        else
        {
            code = 404;
            body = JSONValue(["error": JSONValue("not found")]);
        }
    }
    catch (Exception e)
    {
        code = 500;
        body = JSONValue(["error": JSONValue(e.msg)]);
    }

    auto payload = body.toString;
    auto resp = appender!string;
    resp.put("HTTP/1.1 ");
    resp.put(code.to!string);
    resp.put(code == 200 ? " OK\r\n" : " ERR\r\n");
    resp.put("Content-Type: application/json\r\n");
    resp.put("Content-Length: ");
    resp.put(payload.length.to!string);
    resp.put("\r\nConnection: close\r\n\r\n");
    resp.put(payload);
    client.send(resp.data);
}
