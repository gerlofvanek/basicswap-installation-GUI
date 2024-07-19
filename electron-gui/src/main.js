const { app, BrowserWindow, ipcMain, dialog, Menu } = require('electron');
const path = require('path');
const url = require('url');
const { spawn } = require('child_process');
const fs = require('fs');

let mainWindow;
let appDataFilePath = path.join(app.getPath('userData'), 'app-data.json');
let appData = {};

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

    const emptyMenu = Menu.buildFromTemplate([]);
    Menu.setApplicationMenu(emptyMenu);

    mainWindow.on('closed', function () {
        mainWindow = null;
    });

    loadAppData();
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
    const result = await dialog.showOpenDialog(mainWindow, {
        properties: ['openDirectory']
    });
    return result;
});

ipcMain.on('execute-powershell', (event, installPath, selectedCoins, password) => {
    appData.installPath = installPath;
    appData.selectedCoins = selectedCoins;
    saveAppData();
    executePowerShellScript(event, installPath, selectedCoins, password);
});

function executePowerShellScript(event, installPath, selectedCoins, password) {
    const scriptPath = path.join(app.getAppPath(), 'build', 'part1-install.ps1');

    const childProcess = spawn('powershell.exe', [
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptPath,
        '-INSTALL_PATH',
        installPath,
        '-SELECTED_COINS',
        selectedCoins,
        '-WALLET_PASSWORD',
        password
    ]);

    childProcess.stdout.on('data', (data) => {

        let match = data.toString().match(/PROGRESS:\s*(\d+)/);
        if (match) {
            let progress = parseInt(match[1]);
            event.sender.send('update-progress', progress);
        }

        event.sender.send('powershell-output', data.toString());
    });

    childProcess.stderr.on('data', (data) => {
        event.sender.send('powershell-error', data.toString());
    });

    childProcess.on('error', (error) => {
        event.sender.send('powershell-error', error.message);
    });

    childProcess.on('exit', (code) => {
        event.sender.send('powershell-exit', code);
        if (code === 0) {
            executeSecondScript(event, installPath, selectedCoins);
        }
    });
}

function executeSecondScript(event, installPath, selectedCoins, password) {
    const secondScriptPath = path.join(app.getAppPath(), 'build', 'part2-install.ps1');

    const childProcess = spawn('powershell.exe', [
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        secondScriptPath,
        '-INSTALL_PATH',
        installPath,
        '-SELECTED_COINS',
        selectedCoins,
        '-WALLET_PASSWORD',
        password
    ]);

    childProcess.stdout.on('data', (data) => {
        if (data.toString().includes("IMPORTANT")) {
            event.sender.send('update-progress', 100);
        }

        let match = data.toString().match(/PROGRESS:\s*(\d+)/);
        if (match) {
            let progress = parseInt(match[1]);
            event.sender.send('update-progress', progress);
        }

        let matched = data.toString().match(/\[INFO\] Monero selected\. Current XMR height: (\d+)/);
        if (matched && matched[1]) {
            let height = matched[1];
            event.sender.send('update-xmr-height', height);
        }

        event.sender.send('powershell-output', data.toString());
    });

    childProcess.stderr.on('data', (data) => {
        console.error('Second script stderr:', data.toString());
        event.sender.send('powershell-error', data.toString());
    });

    childProcess.on('error', (error) => {
        console.error('Second script error:', error.message);
        event.sender.send('powershell-error', error.message);
    });

    childProcess.on('exit', (code) => {
        console.log(`Second script exited with code ${code}`);
        event.sender.send('second-script-exit', code);  // Send custom event
    });
}

function loadAppData() {
    try {
        if (fs.existsSync(appDataFilePath)) {
            const data = fs.readFileSync(appDataFilePath, 'utf8');
            appData = JSON.parse(data);
        }
    } catch (err) {
        console.error('Error loading app data:', err);
    }
}

function saveAppData() {
    try {
        fs.writeFileSync(appDataFilePath, JSON.stringify(appData, null, 2), 'utf8');
    } catch (err) {
        console.error('Error saving app data:', err);
    }
}