const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld("electron", {
    selectDirectory: () => {
        return ipcRenderer.invoke('select-directory');
    },
    executePowerShell: (installPath, selectedCoins) => {
        ipcRenderer.send('execute-powershell', installPath, selectedCoins);
    },
    receivePowerShellOutput: (func) => {
        ipcRenderer.on('powershell-output', (event, ...args) => func(...args));
    },
    receivePowerShellError: (func) => {
        ipcRenderer.on('powershell-error', (event, ...args) => func(...args));
    },
    receivePowerShellExit: (func) => {
        ipcRenderer.on('powershell-exit', (event, ...args) => func(...args));
    },
    receiveUpdateProgress: (func) => {
        ipcRenderer.on('update-progress', (event, ...args) => func(...args));
    },
    receiveXMRHeightUpdate: (func) => {
        ipcRenderer.on('update-xmr-height', (event, ...args) => func(...args));
    },
    closeApp: () => {
        ipcRenderer.send('close-app');
    }
});
