function updateProgress(percentage) {
    const progressStatus = document.querySelector('.progress-status');
    if (progressStatus) {
        progressStatus.style.width = percentage + '%';
    }

    const progressText = document.getElementById('progress-text');

    if (progressText) {
        switch (percentage) {
            case 5:
                progressText.textContent = '5% - Booting up the oven... 🖥️🔥';
                break;
            case 15:
                progressText.textContent = '15% - Parsing the ingredients... 📝🥣';
                break;
            case 20:
                progressText.textContent = '20% - Laying out code blocks... or brownie blocks! 🧱🍫';
                break;
            case 25:
                progressText.textContent = '25% - Setting the framework (and oven) to optimal temp... ⚙️🌡️';
                break;
            case 35:
                progressText.textContent = '35% - Debugging dough discrepancies! 🐞🍪';
                break;
            case 40:
                progressText.textContent = '40% - Embedding sweet data clusters... 🍬📊';
                break;
            case 45:
                progressText.textContent = '45% - Preheating the compiler... and oven! 💻🔥';
                break;
            case 50:
                progressText.textContent = '50% - Halfway through baking the code! 💾🍕';
                break;
            case 60:
                progressText.textContent = '60% - Layers compiling smoothly... like icing! 🍰💾';
                break;
            case 70:
                progressText.textContent = '70% - Pulling flavor libraries from the pantry... ehm, cloud! ☁️🍩';
                break;
            case 100:
                progressText.textContent = '100% - Code baked flawlessly! Ready for a byte! 🎉🥧';
                break;
            default:
                if (percentage < 50) {
                    progressText.textContent = percentage + '% 🔄';
                } else if (percentage < 100) {
                    progressText.textContent = percentage + '% ✨';
                }
                break;
            }
        }
    }

document.addEventListener('DOMContentLoaded', function () {
    const coinSelection = document.getElementById('coinSelection');
    const selectInstallationPathButton = document.getElementById('select-installation-path');
    const selectedPathElement = document.getElementById('selected-path');
    const startInstallButton = document.getElementById('startInstallButton');
    const toPage2Button = document.getElementById('to-page2');
    const toPage4Button = document.getElementById('to-page4');
    const toPage5Button = document.getElementById('to-page5');
    const backButton2 = document.getElementById('backButton2');
    const backButton3 = document.getElementById('backButton3');
    const backButton4 = document.getElementById('backButton4');
    const outputTextarea = document.getElementById('output');

// removed Dash, PIVX and Decred for now (needs update/fixes)
    const coinsList = ["Particl", "Monero", "Wownero", "Bitcoin", "Litecoin", "Firo"];
    let selectedCoins = {};
    let installationPath = '';
    const electron = window.electron;

    const closeButton = document.getElementById('window-all-closed');

       closeButton.addEventListener('click', () => {
           electron.closeApp();
       });

    function showCustomAlert(message) {
        let customAlert = document.getElementById('custom-alert');
        let customAlertText = document.getElementById('custom-alert-text');
        let overlay = document.getElementById('overlay');

        customAlertText.textContent = message;
        customAlert.style.display = 'flex';
        overlay.style.display = 'block';
    }

    function hideCustomAlert() {
        let customAlert = document.getElementById('custom-alert');
        let overlay = document.getElementById('overlay');

        customAlert.style.display = 'none';
        overlay.style.display = 'none';
    }

    document.getElementById('custom-alert-close').addEventListener('click', hideCustomAlert);

    coinsList.forEach((coin) => {
        const coinContainer = document.createElement('div');
        coinContainer.className = 'coin-container';

        const coinImage = document.createElement('img');
        coinImage.src = `images/coins/${coin}.png`;
        coinImage.alt = coin;
        coinImage.width = 20;
        coinImage.height = 20;

        const coinName = document.createElement('div');
        coinName.className = 'coin-name';
        coinName.textContent = coin;

        if (coin === 'Particl') {
            coinContainer.classList.add('default');
            coinName.textContent += ' (Default)';
        }

        if (coin === 'Test') {
            coinContainer.classList.add('disabled');
            coinName.textContent += ' (Disabled)';
        }

        coinContainer.appendChild(coinImage);
        coinContainer.appendChild(coinName);
        coinSelection.appendChild(coinContainer);

        if (coin !== 'Particl' && coin !== 'Test') {
            coinContainer.addEventListener('click', function () {
                this.classList.toggle('selected');
                selectedCoins[coin] = this.classList.contains('selected');

                const xmrHeightDiv = document.querySelector('.xmr-height-enabled');
                if (selectedCoins["Monero"]) {
                    xmrHeightDiv.style.display = 'block';
                } else {
                    xmrHeightDiv.style.display = 'none';
                }
            });
        }
    });

    selectInstallationPathButton.addEventListener('click', async () => {
        selectedPathElement.textContent = "Fetching path...";

        const result = await electron.selectDirectory();
        if (!result.canceled && result.filePaths.length > 0) {
            installationPath = result.filePaths[0];
            selectedPathElement.textContent = installationPath;
            document.getElementById('INSTALL_PATH_1').textContent = installationPath;
            document.getElementById('INSTALL_PATH_2').textContent = installationPath;
            console.log("Updating INSTALL_PATH with:", installationPath);
        } else {
            selectedPathElement.textContent = "Path selection canceled";
        }
    });

    toPage2Button.addEventListener('click', function () {
        if (installationPath) {
            document.getElementById('page1').style.display = 'none';
            document.getElementById('page2').style.display = 'block';
        } else {
            showCustomAlert("Please select the installation path first!");
        }
    });

    backButton2.addEventListener('click', function () {
        document.getElementById('page2').style.display = 'none';
        document.getElementById('page1').style.display = 'block';
    });

    startInstallButton.addEventListener('click', function () {
        const selectedCoinNames = Object.keys(selectedCoins).filter(coin => selectedCoins[coin]);
        if (selectedCoinNames.length > 0) {
            document.getElementById('page2').style.display = 'none';
            document.getElementById('page3').style.display = 'block';
            console.log('Starting installation with path:', installationPath, 'and coins:', selectedCoinNames);
            electron.executePowerShell(installationPath, selectedCoinNames.join(','));
        } else {
            showCustomAlert("Please select at least one coin to install!");
        }
    });

    backButton3.addEventListener('click', function () {
        document.getElementById('page3').style.display = 'none';
        document.getElementById('page2').style.display = 'block';
    });

    backButton4.addEventListener('click', function () {
        document.getElementById('page5').style.display = 'none';
        document.getElementById('page4').style.display = 'block';
    });

    toPage4Button.addEventListener('click', function () {
        document.getElementById('page3').style.display = 'none';
        document.getElementById('page4').style.display = 'block';
    });

    toPage5Button.addEventListener('click', function () {
        document.getElementById('page4').style.display = 'none';
        document.getElementById('page5').style.display = 'block';
    });

    electron.receivePowerShellOutput((data) => {
        console.log('Received data from PowerShell:', data);
        const matchProgress = data.match(/PROGRESS:(\d+)/);

        if (matchProgress) {
            const progress = parseInt(matchProgress[1], 10);
            console.log('Progress:', progress);
            updateProgress(progress);
        } else if (data.includes("IMPORTANT")) {
            console.log('Detected IMPORTANT keyword.');
            updateProgress(100);
            document.getElementById('to-page4').style.display = 'block';

            const importantOutputDiv = document.getElementById('important-output');
            if (importantOutputDiv) {
                const messageDiv = document.createElement('div');
                messageDiv.textContent = data;
                importantOutputDiv.appendChild(messageDiv);
                importantOutputDiv.scrollTop = importantOutputDiv.scrollHeight;
            }
        }

        outputTextarea.value += data;
        outputTextarea.scrollTop = outputTextarea.scrollHeight;
    });

    electron.receivePowerShellError((error) => {
        outputTextarea.value += `[ALERT]: ${error}\n`;
        outputTextarea.scrollTop = outputTextarea.scrollHeight;
    });

    electron.receivePowerShellExit((code) => {
        // Handle PowerShell script exit
        outputTextarea.value += `Child process exited with code ${code}\n`;
        outputTextarea.scrollTop = outputTextarea.scrollHeight;
        if (code === 0) {
            // Notify main process to start the second script
            electron.send('start-second-script');
        }
    });

    electron.receiveSecondScriptExit((code) => {
        outputTextarea.value += `Second script exited with code ${code}\n`;
        outputTextarea.scrollTop = outputTextarea.scrollHeight;
    });

    electron.receiveUpdateProgress((percentage) => {
        console.log('Received progress update:', percentage);
        updateProgress(percentage);
    });

    electron.receiveXMRHeightUpdate((height) => {
        const importantOutput = document.getElementById('update-xmr-height');
        importantOutput.textContent = `Current XMR height: ${height}`;
    });

    function createProgressBar() {
        const progressBar = document.createElement('div');
        progressBar.className = 'progress-bar';
        const progressStatus = document.createElement('div');
        progressStatus.className = 'progress-status';

        progressBar.appendChild(progressStatus);

        return progressBar;
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const importantOutputDiv = document.getElementById('important-output');
    const toggleButton = document.getElementById('toggle-important-output');
    const showTextSpan = document.getElementById('show-text');

    showTextSpan.innerHTML = 'SHOW 24 WORDS RECOVERY PHRASE';

    importantOutputDiv.style.display = 'none';
    toggleButton.style.display = 'block';

    toggleButton.addEventListener('click', () => {
        if (importantOutputDiv.style.display === 'none') {
            importantOutputDiv.style.display = 'block';
            showTextSpan.innerHTML = 'HIDE 24 WORDS RECOVERY PHRASE';
        } else {
            importantOutputDiv.style.display = 'none';
            showTextSpan.innerHTML = 'SHOW 24 WORDS RECOVERY PHRASE';
        }
    });

    electron.receivePowerShellOutput((data) => {
        if (data.includes('IMPORTANT')) {
            data = data.replace('Done.', '');
            data = data.replace('IMPORTANT - Save your particl wallet recovery phrase:', '');

            const words = data.split(' ');

            const wrappedText = words.map(word => `<span class="word">${word}</span>`).join(' ');

            importantOutputDiv.innerHTML = wrappedText;
            toggleButton.style.display = 'block';
        }
    });

    electron.receiveXMRHeightUpdate((height) => {
        const importantOutput = document.getElementById('update-xmr-height');
        importantOutput.textContent = `Current XMR height: ${height}`;
    });
});