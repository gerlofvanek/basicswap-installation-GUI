const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const url = require('url');
const { spawn } = require('child_process');

let mainWindow;

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1280,
        height: 720,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            enableRemoteModule: false,
            preload: path.join(__dirname, 'renderer/preload.js'),
        },
    });
    mainWindow.loadURL(
        url.format({
            pathname: path.join(__dirname, 'renderer/index.html'),
            protocol: 'file:',
            slashes: true,
        })
    );
    mainWindow.on('closed', function () {
        mainWindow = null;
    });
}

app.on('ready', createWindow);

app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', function () {
    if (mainWindow === null) {
        createWindow();
    }
});

ipcMain.on('close-app', () => {
    app.quit();
});

ipcMain.handle('select-directory', async (event) => {
    return await dialog.showOpenDialog(mainWindow, {
        properties: ['openDirectory']
    });
});

ipcMain.on('execute-powershell', (event, installPath, selectedCoins) => {
    const scriptPath = path.join(app.getAppPath(), 'build', 'basicswap-install-windows.ps1');

    const childProcess = spawn('powershell.exe', [
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptPath,
        '-INSTALL_PATH',
        installPath,
        '-SELECTED_COINS',
        selectedCoins
    ]);

childProcess.stdout.on('data', (data) => {
    console.log('stdout data:', data.toString());

    if (data.toString().includes("IMPORTANT")) {
        event.sender.send('update-progress', 100);
        console.log('Sent progress update: 100 (IMPORTANT detected)');
    }

    let match = data.toString().match(/PROGRESS:\s*(\d+)/);
    if (match) {
        let progress = parseInt(match[1]);
        event.sender.send('update-progress', progress);
        console.log('Sent progress update:', progress);
    }

    let matched = data.toString().match(/\[INFO\] Monero selected\. Current XMR height: (\d+)/);

    if (matched && matched[1]) {
        let height = matched[1];
        event.sender.send('update-xmr-height', height);
    }

    event.sender.send('powershell-output', data.toString());
});

    childProcess.stderr.on('data', (data) => {
        console.error('stderr data:', data.toString());
        event.sender.send('powershell-error', data.toString());
    });

    childProcess.on('error', (error) => {
        console.error('Child process error:', error.message);
        event.sender.send('powershell-error', error.message);
    });

    childProcess.on('exit', (code) => {
        console.log(`Child process exited with code ${code}`);
        event.sender.send('powershell-exit', code);
    });
});