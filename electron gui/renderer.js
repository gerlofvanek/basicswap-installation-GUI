const coinSelection = document.getElementById('coinSelection');
const coinsList = ["Monero", "Bitcoin", "Litecoin", "Dash", "PIVX", "Firo"];
let selectedCoins = {};
let installationPath = '';

window.onload = () => {
  // Populate coins checkboxes
  coinsList.forEach((coin) => {
    const checkboxContainer = document.createElement('div');
    checkboxContainer.className = 'checkbox-container';
  
    const checkbox = document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.id = coin;
    checkbox.name = coin;
    checkbox.value = coin;
    checkbox.checked = coin === 'Particl';
    if (coin === 'Particl') checkbox.disabled = true;
  
    const label = document.createElement('label');
    label.htmlFor = coin;
    label.appendChild(document.createTextNode(coin));
  
    checkboxContainer.appendChild(checkbox);
    checkboxContainer.appendChild(label);
    coinSelection.appendChild(checkboxContainer);
  
    // Add the coin to the selected coins object
    selectedCoins[coin] = checkbox.checked;
  });

  // Add event listeners
  document.getElementById('select-installation-path').addEventListener('click', async () => {
    installationPath = await window.myAPI.selectDirectory();
    document.getElementById('selected-path').textContent = installationPath;
  });

  document.getElementById('to-page2').addEventListener('click', () => {
    document.getElementById('page1').style.display = 'none';
    document.getElementById('page2').style.display = 'block';
  });

  coinSelection.addEventListener('change', (e) => {
    if (e.target && e.target.nodeName === 'INPUT') {
      selectedCoins[e.target.value] = e.target.checked;
    }
  });

  window.myAPI.onCommandData((event, data) => {
    const logTextArea = document.getElementById('log');
    logTextArea.value += data;
    logTextArea.scrollTop = logTextArea.scrollHeight;
  });

  document.getElementById('startInstallButton').addEventListener('click', async () => {
    const selectedCoinsList = coinsList.filter(coin => document.getElementById(coin).checked);
    document.getElementById('page2').style.display = 'none';
    document.getElementById('page3').style.display = 'block';

    // If there are no selected coins, show an error dialog
    if (selectedCoinsList.length === 0) {
      window.myAPI.showErrorBox('Error', 'Please select at least one coin.');
      return;
    }

    // Call your script with the selected options
    const cmd = `bash ./basicswap-install.sh --install-path "${installationPath}" --selected-coins "${selectedCoinsList.join(',').toLowerCase()}"`;

    // Execute the command and send updates to the textarea
    try {
      window.myAPI.runCommand(cmd);
    } catch (error) {
      console.error('Error running command:', error);
    }

    const logTextArea = document.getElementById('logTextArea');
    window.addEventListener('message', (event) => {
      if (event.data.type === 'command-data') {
        logTextArea.value += event.data.data;
        logTextArea.scrollTop = logTextArea.scrollHeight;
      }
    });

    // Show a message box when the process is done
    window.myAPI.runCommand(cmd).then(() => {
      window.myAPI.showMessageBox({
        type: 'info',
        title: 'Installation finished',
        message: `Installation has finished`
      });
    }).catch((error) => {
      console.error('Error running command:', error);
    });
  });

};
