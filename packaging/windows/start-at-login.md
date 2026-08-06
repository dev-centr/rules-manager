# Rules Manager — start at login (Windows)

## Daemon (rulesd)

Option A — Run key (current user):

```powershell
$exe = "C:\code\github.com\dev-centr\rules-manager\daemon\rulesd.exe"
$cfg = "C:\code\rules-manager.config.json"
$cmd = "`"$exe`" --serve --config `"$cfg`""
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
  -Name "DevCentrRulesd" -Value $cmd -PropertyType String -Force
```

Option B — Task Scheduler: trigger *At log on*, action = `rulesd.exe --serve --config …`.

## Tray UI

Prefer the packaged Electron app Login Item, or:

```powershell
# After `pnpm dist`, point Startup at the installed Rules Manager.exe
# Or set from the tray Settings when wired: app.setLoginItemSettings({ openAtLogin: true })
```

Junctions are not required. Set `rules_repo_path` in the config JSON.
