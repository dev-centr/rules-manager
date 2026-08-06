# Rules Manager

Compose and watch [agent-rules](https://github.com/dev-centr/agent-rules) (personal home: [AMDphreak/agent-rules](https://github.com/AMDphreak/agent-rules)).

**Stack**

- `daemon/` — **`rulesd`** (D): marker compose, file watch, localhost JSON IPC
- `ui/` — Electron tray app (Windows / macOS / Linux GNOME·KDE·XFCE·COSMIC)
- `packaging/` — start-at-login helpers (Run key / LaunchAgent / systemd --user)
- `docs/` — install + DE tray notes (AsciiDoc)

Junctions/hardlinks to agent-rules are a **temporary path hack**. Prefer configuring `rules_repo_path` in `$CODE_ROOT/rules-manager.config.json` (see `config/rules-manager.example.json`).

## Quick start

```powershell
# 1) Write default config (points at AMDphreak agent-rules if present)
cd daemon
dub run -- --write-config --code-root C:\code

# 2) One-shot compose
dub run -- --compose

# 3) Daemon (watch + IPC :17355)
dub run -- --serve

# 4) Tray UI (another terminal)
cd ..\ui
pnpm install
# If electron.exe is missing (ignored build scripts), run:
#   pnpm exec node node_modules/electron/install.js
pnpm start
```

CLI: `--version`, `--debug-dump`, `--config`, `--code-root`.

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

Edits inside markers patch back to `RULES.md` (global) or `profiles/<id>.overlay.md` (machine). Unmarked body fails loud.

## Product essentials

See `docs/app-essentials-checklist.md` and [Software Product Essentials](https://github.com/dev-centr/general-knowledge). Install docs: `docs/modules/ROOT/pages/how-to-install.adoc`.

## Changelog

See [CHANGELOG.adoc](CHANGELOG.adoc).

## License

MIT
