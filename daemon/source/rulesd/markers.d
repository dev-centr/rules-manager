module rulesd.markers;

import std.array : appender;
import std.exception : enforce;
import std.string : indexOf, strip, stripRight;

enum globalBegin = "<!-- rules:global:begin -->";
enum globalEnd = "<!-- rules:global:end -->";
enum machineBegin = "<!-- rules:machine:begin -->";
enum machineEnd = "<!-- rules:machine:end -->";

struct Sections
{
    string globalBody;
    string machineBody;
    bool hasMarkers;
}

Sections parseComposed(string text)
{
    Sections s;
    auto gb = text.indexOf(globalBegin);
    auto ge = text.indexOf(globalEnd);
    auto mb = text.indexOf(machineBegin);
    auto me = text.indexOf(machineEnd);

    if (gb < 0 && mb < 0)
    {
        s.hasMarkers = false;
        return s;
    }

    enforce(gb >= 0 && ge > gb, "composed file missing or malformed rules:global markers");
    enforce(mb >= 0 && me > mb, "composed file missing or malformed rules:machine markers");

    s.hasMarkers = true;
    s.globalBody = text[gb + globalBegin.length .. ge].strip;
    s.machineBody = text[mb + machineBegin.length .. me].strip;
    return s;
}

string composeDocument(string globalBody, string machineBody)
{
    auto app = appender!string;
    app.put(globalBegin);
    app.put("\n");
    app.put(globalBody.stripRight);
    app.put("\n");
    app.put(globalEnd);
    app.put("\n\n");
    app.put(machineBegin);
    app.put("\n");
    app.put(machineBody.stripRight);
    app.put("\n");
    app.put(machineEnd);
    app.put("\n");
    return app.data;
}

string fillConstants(string rulesText, string[string] constants)
{
    import std.regex : regex, replaceAll;

    auto result = rulesText;
    foreach (key, value; constants)
    {
        auto re = regex(`(?m)^(\-\s*` ~ key ~ `\s*:\s*).*$`);
        result = replaceAll(result, re, "$1`" ~ value ~ "`");
    }
    return result;
}
