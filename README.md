<a id="readme-top"></a>
<div align="center">
  <a href="https://github.com/dev-centr/rules-manager/graphs/contributors"><img src="https://img.shields.io/github/contributors/dev-centr/rules-manager.svg?style=for-the-badge" alt="Contributors"></a>
  <a href="https://github.com/dev-centr/rules-manager/network/members"><img src="https://img.shields.io/github/forks/dev-centr/rules-manager.svg?style=for-the-badge" alt="Forks"></a>
  <a href="https://github.com/dev-centr/rules-manager/stargazers"><img src="https://img.shields.io/github/stars/dev-centr/rules-manager.svg?style=for-the-badge" alt="Stargazers"></a>
  <a href="https://github.com/dev-centr/rules-manager/issues"><img src="https://img.shields.io/github/issues/dev-centr/rules-manager.svg?style=for-the-badge" alt="Issues"></a>
  <a href="https://github.com/dev-centr/rules-manager/blob/main/LICENSE"><img src="https://img.shields.io/github/license/dev-centr/rules-manager.svg?style=for-the-badge" alt="License"></a>

  <h3 align="center">Rules Manager</h3>
  <p align="center">
    Compose and watch agent-rules: D rulesd daemon + Electron tray UI.
    <br />
    <a href="https://github.com/dev-centr/rules-manager/issues">Report Bug</a>
    &middot;
    <a href="https://github.com/dev-centr/rules-manager/issues">Request Feature</a>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#installation">Installation</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## About The Project

Compose and watch [agent-rules](https://github.com/dev-centr/agent-rules).

**Stack**

- `daemon/` — **`rulesd`** (D): marker compose, file watch, localhost JSON IPC
- `ui/` — Electron tray app (Windows / macOS / Linux GNOME·KDE·XFCE·COSMIC)
- `packaging/` — start-at-login helpers (Run key / LaunchAgent / systemd --user)
- `docs/` — install + DE tray notes (AsciiDoc)

Junctions/hardlinks to agent-rules are a **temporary path hack**. Prefer configuring `rules_repo_path` in `$CODE_ROOT/rules-manager.config.json` (see `config/rules-manager.example.json`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Installation

```powershell
# 1) Write default config (points at local agent-rules under CODE_ROOT if present)
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

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### Markers

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

### Product essentials

See `docs/app-essentials-checklist.md` and [Software Product Essentials](https://github.com/dev-centr/general-knowledge). Install docs: `docs/modules/ROOT/pages/how-to-install.adoc`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Changelog

See [CHANGELOG.adoc](CHANGELOG.adoc).

## License

Distributed under the MIT License. See `LICENSE`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

DevCentr.org — support@devcentr.org

Project Link: [https://github.com/dev-centr/rules-manager](https://github.com/dev-centr/rules-manager)

Site: [https://devcentr.org](https://devcentr.org)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
