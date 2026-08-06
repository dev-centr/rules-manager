<a id="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

<div align="center">
  <h1>Rules Manager</h1>
  <p>Compose and watch agent-rules: D rulesd daemon + Electron tray UI.</p>
  <p>
    <a href="https://github.com/dev-centr/rules-manager/issues">Report Bug</a>
    ·
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

Compose and watch [agent-rules](https://github.com/dev-centr/agent-rules) (personal home: [AMDphreak/agent-rules](https://github.com/AMDphreak/agent-rules)).

**Stack**

- `daemon/` — **`rulesd`** (D): marker compose, file watch, localhost JSON IPC
- `ui/` — Electron tray app (Windows / macOS / Linux GNOME·KDE·XFCE·COSMIC)
- `packaging/` — start-at-login helpers (Run key / LaunchAgent / systemd --user)
- `docs/` — install + DE tray notes (AsciiDoc)

Junctions/hardlinks to agent-rules are a **temporary path hack**. Prefer configuring `rules_repo_path` in `$CODE_ROOT/rules-manager.config.json` (see `config/rules-manager.example.json`).

## Installation

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

## Changelog

See [CHANGELOG.adoc](CHANGELOG.adoc).

## License

MIT

## Contact

DevCentr.org - support@devcentr.org

Project Link: https://github.com/dev-centr/rules-manager

Site: https://devcentr.org

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/dev-centr/rules-manager.svg?style=for-the-badge
[contributors-url]: https://github.com/dev-centr/rules-manager/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/dev-centr/rules-manager.svg?style=for-the-badge
[forks-url]: https://github.com/dev-centr/rules-manager/network/members
[stars-shield]: https://img.shields.io/github/stars/dev-centr/rules-manager.svg?style=for-the-badge
[stars-url]: https://github.com/dev-centr/rules-manager/stargazers
[issues-shield]: https://img.shields.io/github/issues/dev-centr/rules-manager.svg?style=for-the-badge
[issues-url]: https://github.com/dev-centr/rules-manager/issues
[license-shield]: https://img.shields.io/github/license/dev-centr/rules-manager.svg?style=for-the-badge
[license-url]: https://github.com/dev-centr/rules-manager/blob/main/LICENSE
