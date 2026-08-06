# Rules Manager

Compose and watch [agent-rules](https://github.com/dev-centr/agent-rules) (personal home: [AMDphreak/agent-rules](https://github.com/AMDphreak/agent-rules)).

**Stack**

- `daemon/` — **`rulesd`** (D): marker compose, file watch, localhost JSON IPC
- `ui/` — Electron tray app (Windows / macOS / Linux GNOME·KDE·XFCE·COSMIC)

Junctions/hardlinks to agent-rules are a **temporary path hack**. Prefer configuring `rules_repo_path` in `$CODE_ROOT/rules-manager.config.json`.

## Quick start

```powershell
# 1) Write default config (points at AMDphreak agent-rules if present)
cd daemon
dub run -- --write-config --code-root C:\code

# 2) Run daemon (compose + watch + IPC :17355)
dub run

# 3) Tray UI (another terminal)
cd ..\ui
pnpm install
pnpm start
```

## Markers

Composed file `$CODE_ROOT/agent-rules.composed.md`:

```markdown
<!-- rules:global:begin -->
…RULES.md with profile constants filled…
<!-- rules:global:end -->

<!-- rules:machine:begin -->
…profiles/<id>.overlay.md…
<!-- rules:machine:end -->
```

## Changelog

See [CHANGELOG.adoc](CHANGELOG.adoc).

## License

MIT
