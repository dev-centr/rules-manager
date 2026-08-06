const { app, BrowserWindow, Tray, Menu, nativeImage, shell, dialog } = require("electron");
const path = require("path");
const fs = require("fs");
const http = require("http");

const IPC_PORT = process.env.RULESD_PORT || 17355;
let tray = null;
let settingsWin = null;

function ipcGet(pathname) {
  return new Promise((resolve, reject) => {
    const req = http.get({ host: "127.0.0.1", port: IPC_PORT, path: pathname, timeout: 3000 }, (res) => {
      let data = "";
      res.on("data", (c) => (data += c));
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    });
    req.on("error", reject);
    req.on("timeout", () => {
      req.destroy();
      reject(new Error("timeout"));
    });
  });
}

function ipcPost(pathname) {
  return new Promise((resolve, reject) => {
    const req = http.request(
      { host: "127.0.0.1", port: IPC_PORT, path: pathname, method: "POST", timeout: 10000 },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(e);
          }
        });
      }
    );
    req.on("error", reject);
    req.end();
  });
}

function trayIcon() {
  const asset = path.join(__dirname, "assets", "tray.png");
  if (fs.existsSync(asset)) {
    const img = nativeImage.createFromPath(asset);
    if (process.platform === "darwin") img.setTemplateImage(true);
    return img;
  }
  const size = 16;
  const buf = Buffer.alloc(size * size * 4);
  for (let i = 0; i < size * size; i++) {
    buf[i * 4] = 20;
    buf[i * 4 + 1] = 184;
    buf[i * 4 + 2] = 166;
    buf[i * 4 + 3] = 255;
  }
  return nativeImage.createFromBuffer(buf, { width: size, height: size });
}

async function refreshMenu() {
  let statusLabel = "rulesd: unreachable";
  try {
    const st = await ipcGet("/status");
    statusLabel = `Status: ${st.status}${st.dirty ? " (dirty)" : ""} · ${st.profile || "?"}`;
    if (st.error) statusLabel += ` · err: ${st.error}`;
  } catch {
    /* leave unreachable */
  }

  const login = app.getLoginItemSettings ? app.getLoginItemSettings() : { openAtLogin: false };

  const template = [
    { label: "Rules Manager", enabled: false },
    { label: statusLabel, enabled: false },
    { type: "separator" },
    {
      label: "Compose now",
      click: async () => {
        try {
          const r = await ipcPost("/compose");
          dialog.showMessageBox({ message: `Composed ${r.composed}\nprofile=${r.profile}` });
        } catch (e) {
          dialog.showErrorBox("Compose failed", String(e.message || e));
        }
      },
    },
    {
      label: "Open composed file",
      click: async () => {
        try {
          const st = await ipcGet("/status");
          if (st.composed) shell.openPath(st.composed);
        } catch (e) {
          dialog.showErrorBox("Open failed", String(e.message || e));
        }
      },
    },
    {
      label: "Settings…",
      click: () => openSettings(),
    },
    {
      label: "Start tray at login",
      type: "checkbox",
      checked: !!login.openAtLogin,
      click: (item) => {
        if (app.setLoginItemSettings) {
          app.setLoginItemSettings({ openAtLogin: item.checked, openAsHidden: true });
        }
      },
    },
    { type: "separator" },
    {
      label: "About",
      click: async () => {
        let detail =
          "Electron tray UI + rulesd (D) daemon.\nComposes global + machine agent-rules sections.\nTray: Windows, macOS, Linux (GNOME/KDE/XFCE/COSMIC).";
        try {
          const d = await ipcGet("/debug");
          detail += `\n\nrulesd ${d.version} · host ${d.hostname} · profile ${d.profile}`;
        } catch {
          /* ignore */
        }
        dialog.showMessageBox({
          title: "About Rules Manager",
          message: "Dev-Centr Rules Manager 0.1.0",
          detail,
        });
      },
    },
    {
      label: "Copy debug dump",
      click: async () => {
        try {
          const d = await ipcGet("/debug");
          const { clipboard } = require("electron");
          clipboard.writeText(JSON.stringify(d, null, 2));
          dialog.showMessageBox({ message: "Debug dump copied to clipboard." });
        } catch (e) {
          dialog.showErrorBox("Debug dump failed", String(e.message || e));
        }
      },
    },
    {
      label: "Quit",
      click: () => app.quit(),
    },
  ];
  tray.setContextMenu(Menu.buildFromTemplate(template));
  tray.setToolTip(statusLabel);
}

function openSettings() {
  if (settingsWin) {
    settingsWin.focus();
    return;
  }
  settingsWin = new BrowserWindow({
    width: 520,
    height: 420,
    webPreferences: { nodeIntegration: true, contextIsolation: false },
    title: "Rules Manager",
  });
  settingsWin.loadFile(path.join(__dirname, "settings.html"));
  settingsWin.on("closed", () => {
    settingsWin = null;
  });
}

app.whenReady().then(() => {
  if (process.platform === "darwin" && app.dock) app.dock.hide();

  tray = new Tray(trayIcon());
  if (process.platform === "darwin") {
    try {
      tray.setIgnoreDoubleClickEvents(true);
    } catch {
      /* ignore */
    }
  }
  refreshMenu();
  setInterval(refreshMenu, 5000);
});

app.on("window-all-closed", (e) => {
  e.preventDefault();
});
