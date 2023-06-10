#Requires -Version 5.0

function Install-Dependencies-Windows {
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    choco install python3 protoc protobuf curl jq git wget -y
}

Write-Host "Checking and installing prerequisites..."
Install-Dependencies-Windows

Write-Host "Please enter the absolute path to the directory where you wish to install BasicSwap:"
$INSTALL_PATH = Read-Host

# Prompt the user for the coins they want to include
Write-Host "Please choose the coins you want to include (separate with commas, no spaces):"
Write-Host "Options: monero, bitcoin, litecoin, dash, pivx, firo"
$SELECTED_COINS = Read-Host

# Verify the user's input
if ($SELECTED_COINS -notmatch '^[a-zA-Z,]+$') {
    Write-Host "Invalid input. Please only use comma-separated coin names without spaces."
    exit 1
}

# Set the location where the local nodes for the coins that will be included in BasicSwap will be installed
$COINDATA_PATH = Join-Path $INSTALL_PATH "coindata"
Write-Host "The path to the coins data dirs folder is $COINDATA_PATH"

# Check if the coins data directory exists and ask the user if they want to do a fresh installation
if (Test-Path $COINDATA_PATH) {
    Write-Host "The coins data directory already exists at $COINDATA_PATH."
    $response = Read-Host "Would you like to perform a fresh installation and remove the existing directory? (y/N)"
    if ($response -match "^(y|yes)$") {
        Write-Host "Removing coins data dir folder to start a fresh installation..."
        Remove-Item $COINDATA_PATH -Recurse -Force
    }
}

# Create coins data dir
New-Item -ItemType Directory -Force -Path $COINDATA_PATH

# Create Python virtual environment
$VENV_PATH = Join-Path $INSTALL_PATH "basicswap_venv"
python -m venv $VENV_PATH
$ENV_PATH = Join-Path $VENV_PATH "Scripts"

# Activate the virtual environment
$activate = Join-Path $ENV_PATH "Activate"
. $activate
Write-Host "The virtual environment uses $(python --version)"

# Fetch and install the coincurve library
$COINCURVE_PATH = Join-Path $COINDATA_PATH "coincurve-anonswap"
$COINCURVE_URL = "https://github.com/tecnovert/coincurve/archive/refs/tags/anonswap_v0.1.tar.gz"
$COINCURVE_FILE = Join-Path $COINDATA_PATH "anonswap_v0.1.tar.gz"
Invoke-WebRequest -Uri $COINCURVE_URL -OutFile $COINCURVE_FILE
Expand-Archive -Path $COINCURVE_FILE -DestinationPath $COINDATA_PATH
Move-Item -Path (Join-Path $COINDATA_PATH "coincurve-anonswap_v0.1") -Destination $COINCURVE_PATH
cd $COINCURVE_PATH
pip install .

# Clone, build, and install the Basic Swap DEX
$BASICSWAP_PATH = Join-Path $INSTALL_PATH "basicswap"
git clone https://github.com/tecnovert/basicswap.git $BASICSWAP_PATH
cd $BASICSWAP_PATH
protoc -I=basicswap --python_out=basicswap basicswap/messages.proto
pip install protobuf==3.20.*
pip install .

# Initialize the coins data directory
if ($SELECTED_COINS.Contains("monero")) {
    $CURRENT_XMR_HEIGHT = (Invoke-WebRequest -Uri "https://localmonero.co/blocks/api/get_stats" | ConvertFrom-Json).height
    basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --xmrrestoreheight=$CURRENT_XMR_HEIGHT --usebtcfastsync
} else {
    $CURRENT_XMR_HEIGHT = "0"
    basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --usebtcfastsync
}


Write-Host "To start the Basic Swap DEX, run the command below:"
Write-Host "cd $INSTALL_PATH; . $activate; basicswap-run --datadir=$COINDATA_PATH"
Write-Host "!!!DO NOT FORGET TO WRITE DOWN THE 24 WORDS (RECOVERY PHRASE) PRINTED A FEW LINES ABOVE!!!"
Write-Host "If you have added XMR support, please write down the CURRENT_XMR_HEIGHT=$CURRENT_XMR_HEIGHT"
Write-Host "You will need this number if you want to restore the XMR node from the seed phrase"