# Read the configuration from the JSON file
$configPath = Join-Path $env:TEMP "basicswap_config.json"
$config = Get-Content $configPath | ConvertFrom-Json

$INSTALL_PATH = $config.INSTALL_PATH
$SELECTED_COINS = $config.SELECTED_COINS
$WALLET_PASSWORD = $config.WALLET_PASSWORD

# Define paths
$venvPath = Join-Path -Path $INSTALL_PATH -ChildPath "venv"
$COINDATA_PATH = Join-Path $INSTALL_PATH "coindata"
$COINCURVE_REPO_PATH = Join-Path $COINDATA_PATH "coincurve-tecnovert"
$BASICSWAP_PATH = Join-Path $INSTALL_PATH "basicswap"

function LogMessage {
    param(
        [string]$message,
        [string]$type = "INFO"
    )

    if ($type -eq "ERROR") {
        Write-Error $message
    } else {
        Write-Host $message
    }
}

function RefreshEnv {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Ensure-GPG-Installed {
    if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
        LogMessage "[INFO] GPG not found. Installing GPG..."
        try {
            choco install gnupg -y
            RefreshEnv
        } catch {
            LogMessage "Failed to install GPG: $_" "ERROR"
            exit 1
        }
    }
    
    if (Get-Command gpg -ErrorAction SilentlyContinue) {
        LogMessage "[INFO] GPG installed successfully. Version: $(gpg --version | Select-Object -First 1)"
    } else {
        LogMessage "GPG installation failed or not in PATH" "ERROR"
        exit 1
    }
}

LogMessage "##############################################################################"
LogMessage "# 8 Set up Python virtual environment."
LogMessage "##############################################################################"

if (-not (Test-Path $venvPath)) {
    try {
        python -m venv $venvPath
        LogMessage "[INFO] Python virtual environment created."
    } catch {
        LogMessage "Error creating virtual environment: $_" "ERROR"
        exit 1
    }
} else {
    LogMessage "[INFO] Python virtual environment already exists."
}

LogMessage "PROGRESS: 40"

LogMessage "##############################################################################"
LogMessage "# 9 Ensure GPG is installed"
LogMessage "##############################################################################"

Ensure-GPG-Installed

LogMessage "##############################################################################"
LogMessage "# 10 Cloning and setting up coincurve from tecnovert's GitHub fork."
LogMessage "##############################################################################"

try {
    if (Test-Path $COINCURVE_REPO_PATH) {
        LogMessage "[INFO] Coincurve directory already exists. Updating..."
        Set-Location -Path $COINCURVE_REPO_PATH
        git pull
    } else {
        git clone -b bsx_windows https://github.com/tecnovert/coincurve.git $COINCURVE_REPO_PATH
        Set-Location -Path $COINCURVE_REPO_PATH
    }
    python -m pip install .
    LogMessage "[INFO] Successfully installed coincurve from tecnovert's fork."
    LogMessage "PROGRESS: 50"
} catch {
    LogMessage "Error occurred during coincurve setup. Please ensure you have proper network access and permissions: $_" "ERROR"
    exit 1
}

LogMessage "##############################################################################"
LogMessage "# 11 Cloning and setting up BasicSwap from GitHub."
LogMessage "##############################################################################"

try {
    git clone https://github.com/basicswap/basicswap.git $BASICSWAP_PATH
    Set-Location -Path $BASICSWAP_PATH

    if (Test-Path -Path $BASICSWAP_PATH) {
        LogMessage "[INFO] Installing required Python packages for BasicSwap..."
        pip install .
        LogMessage "PROGRESS: 60"
    } else {
        LogMessage "[ERROR] BasicSwap path does not exist after cloning."
        exit 1
    }
} catch {
    LogMessage "Error occurred during BasicSwap setup. Please ensure you have proper network access and permissions: $_" "ERROR"
    exit 1
}

LogMessage "##############################################################################"
LogMessage "# 12 Preparing Basicswap."
LogMessage "##############################################################################"

try {
    RefreshEnv
    if ($SELECTED_COINS.Contains("Monero")) {
        LogMessage "[INFO] Preparing Monero setup. Fetching current XMR height..."
        $CURRENT_XMR_HEIGHT = (Invoke-WebRequest -Uri "https://xmrchain.net/api/networkinfo" | ConvertFrom-Json).data.height
        LogMessage "[INFO] Monero selected. Current XMR height: $CURRENT_XMR_HEIGHT"
        LogMessage "PROGRESS: 70"
        LogMessage "[INFO] Starting basicswap-prepare for Monero. This might take a while.."

        try {
            # $env:WALLET_ENCRYPTION_PWD = $WALLET_PASSWORD
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --xmrrestoreheight=$CURRENT_XMR_HEIGHT --usebtcfastsync
        } catch {
            LogMessage "Error occurred during basicswap-prepare execution for Monero: $_" "ERROR"
            exit 1
        }

        LogMessage "[INFO] BasicSwap with Monero setup and download completed."
    } else {
        LogMessage "[INFO] Preparing BasicSwap."
        LogMessage "PROGRESS: 70"
        LogMessage "[INFO] Starting basicswap-prepare. This might take a while..."

        try {
            # $env:WALLET_ENCRYPTION_PWD = $WALLET_PASSWORD
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --usebtcfastsync
        } catch {
            LogMessage "Error occurred during basicswap-prepare execution: $_" "ERROR"
            exit 1
        }

        LogMessage "[INFO] BasicSwap setup completed."
    }
} catch {
    LogMessage "Error occurred during initial setup steps: $_" "ERROR"
    exit 1
}

LogMessage "[INFO] Setup and installation completed."

# Clean up the temporary configuration file
Remove-Item $configPath
