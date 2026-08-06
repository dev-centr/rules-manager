const { app, BrowserWindow, Tray, Menu, nativeImage, shell, dialog } = require("electron");
const path = require("path");
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
  // 16x16 simple teal square PNG as data URL fallback via empty — Electron needs a file.
  // Generate a minimal nativeImage from buffer.
  const size = 16;
  // 1x1 teal pixel expanded — use empty template on mac; colored on win/linux
  const img = nativeImage.createEmpty();
  if (process.platform === "darwin") {
    return img; // templateImage set below if we had assets; empty still creates a tray slot on some builds
  }
  // Create a small green bitmap
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
  let composed = null;
  try {
    const st = await ipcGet("/status");
    statusLabel = `Status: ${st.status}${st.dirty ? " (dirty)" : ""} · ${st.profile || "?"}`;
    composed = st.composed;
    if (st.error) statusLabel += ` · err: ${st.error}`;
  } catch {
    /* leave unreachable */
  }

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
    { type: "separator" },
    {
      label: "About",
      click: () => {
        dialog.showMessageBox({
          title: "About Rules Manager",
          message: "Dev-Centr Rules Manager 0.1.0",
          detail:
            "Electron tray UI + rulesd (D) daemon.\nComposes global + machine agent-rules sections.\nTray targets: Windows, macOS, Linux (GNOME/KDE/XFCE/COSMIC).",
        });
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
  // Keep running in tray; hide dock on mac when possible
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

  // Open settings on first run? Stay tray-only.
});

app.on("window-all-closed", (e) => {
  // Stay alive for tray
  e.preventDefault();
});
