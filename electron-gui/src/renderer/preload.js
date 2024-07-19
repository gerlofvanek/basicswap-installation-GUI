const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electron', {
    selectDirectory: () => ipcRenderer.invoke('select-directory'),
    executePowerShell: (installPath, selectedCoins) => ipcRenderer.send('execute-powershell', installPath, selectedCoins),
    receivePowerShellOutput: (callback) => ipcRenderer.on('powershell-output', (event, data) => callback(data)),
    receivePowerShellError: (callback) => ipcRenderer.on('powershell-error', (event, error) => callback(error)),
    receivePowerShellExit: (callback) => ipcRenderer.on('powershell-exit', (event, code) => callback(code)),
    receiveUpdateProgress: (callback) => ipcRenderer.on('update-progress', (event, percentage) => callback(percentage)),
    receiveXMRHeightUpdate: (callback) => ipcRenderer.on('update-xmr-height', (event, height) => callback(height)),
    receiveSecondScriptExit: (callback) => ipcRenderer.on('second-script-exit', (event, code) => callback(code)),
    send: (channel, data) => ipcRenderer.send(channel, data),
    closeApp: () => ipcRenderer.send('close-app'),
});