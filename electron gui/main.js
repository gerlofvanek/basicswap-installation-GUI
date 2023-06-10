const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const child_process = require('child_process');
const path = require('path');

function createWindow () {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      enableRemoteModule: false,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  // win.webContents.openDevTools();
  win.loadFile('index.html');
  win.setMenu(null);
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

ipcMain.handle('select-directory', async () => {
  const result = await dialog.showOpenDialog({
    properties: ['openDirectory']
  });

  if (!result.canceled && result.filePaths.length > 0) {
    return result.filePaths[0];
  } else {
    return '';
  }
});

ipcMain.handle('show-error-box', (event, title, content) => {
  dialog.showErrorBox(title, content);
});

ipcMain.handle('show-message-box', (event, options) => {
  dialog.showMessageBox(null, options);
});

ipcMain.handle('run-command', async (event, cmd) => {
  return new Promise((resolve, reject) => {
    const command = child_process.spawn('/bin/bash', ['-c', cmd], {detached: true});

    command.stdout.on('data', (data) => {
      event.sender.send('command-data', data.toString());
    });

    command.stderr.on('data', (data) => {
      event.sender.send('command-data', data.toString());
    });

    command.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Command exited with code ${code}`));
      } else {
        resolve();
      }
    });
  });
});

