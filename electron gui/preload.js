const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld(
  'myAPI', {
    selectDirectory: () => ipcRenderer.invoke('select-directory'),
    showErrorBox: (title, content) => ipcRenderer.invoke('show-error-box', title, content),
    showMessageBox: (options) => ipcRenderer.invoke('show-message-box', options),
    runCommand: (cmd) => ipcRenderer.invoke('run-command', cmd),
    onCommandData: (func) => ipcRenderer.on('command-data', func)
  }
);
