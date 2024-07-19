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
        [string]$type
    )

    if ($type -eq "ERROR") {
        Write-Error $message
    } else {
        Write-Host $message
    }
}

Write-Host "##############################################################################"
Write-Host "# 8 Set up Python virtual environment."
Write-Host "##############################################################################"

LogMessage "[INFO] Setting up Python virtual environment..."

if (-not (Test-Path $venvPath)) {
    try {
        python -m venv $venvPath
        LogMessage "[INFO] Python virtual environment created."
    } catch {
        LogMessage "Error creating virtual environment: $_"
        exit 1
    }
} else {
    LogMessage "[INFO] Python virtual environment already exists."
}

LogMessage "PROGRESS: 40"

Write-Host "##############################################################################"
Write-Host "# 10 Cloning and setting up coincurve from tecnovert's GitHub fork."
Write-Host "##############################################################################"

LogMessage "[INFO] Cloning and setting up coincurve from tecnovert's GitHub fork..."

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
    LogMessage "Error occurred during coincurve setup. Please ensure you have proper network access and permissions: $_"
    exit 1
}

Write-Host "##############################################################################"
Write-Host "# 11 Cloning and setting up BasicSwap from GitHub."
Write-Host "##############################################################################"

LogMessage "[INFO] Cloning and setting up BasicSwap from GitHub..."

try {
    # Check if the branch exists before attempting to clone
    $branchExists = git ls-remote --heads https://github.com/basicswap/basicswap.git | Measure-Object | Select-Object -ExpandProperty Count

    git clone https://github.com/basicswap/basicswap.git $BASICSWAP_PATH
    Set-Location -Path $BASICSWAP_PATH

    if (Test-Path -Path $BASICSWAP_PATH) {
        LogMessage "[INFO] Installing required Python packages for BasicSwap..."
        pip install .
        LogMessage "PROGRESS: 60" "INFO"
    } else {
        LogMessage "[ERROR] BasicSwap path does not exist after cloning."
        exit 1
    }
} catch {
    LogMessage "Error occurred during BasicSwap setup. Please ensure you have proper network access and permissions: $_"
    exit 1
}

Write-Host "##############################################################################"
Write-Host "# 12 Preparing Basicswap."
Write-Host "##############################################################################"

LogMessage "[INFO] Preparing BasicSwap..."

try {
    if ($SELECTED_COINS.Contains("Monero")) {
        LogMessage "[INFO] Preparing Monero setup. Fetching current XMR height..."
        $CURRENT_XMR_HEIGHT = (Invoke-WebRequest -Uri "https://localmonero.co/blocks/api/get_stats" | ConvertFrom-Json).height
        LogMessage "[INFO] Monero selected. Current XMR height: $CURRENT_XMR_HEIGHT" "INFO"
        LogMessage "PROGRESS: 70" "INFO"
        LogMessage "[INFO] Starting basicswap-prepare for Monero. This might take a while.."

        try {
            # WIP $env:WALLET_ENCRYPTION_PWD = $WALLET_PASSWORD
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --xmrrestoreheight=$CURRENT_XMR_HEIGHT --usebtcfastsync
        } catch {
            LogMessage "Error occurred during basicswap-prepare execution for Monero: $_"
            exit 1
        }

        LogMessage "[INFO] BasicSwap with Monero setup and download completed."
    } else {
        LogMessage "[INFO] Preparing BasicSwap." "INFO"
        LogMessage "PROGRESS: 70" "INFO"
        LogMessage "[INFO] Starting basicswap-prepare. This might take a while..."

        try {
            # WIP $env:WALLET_ENCRYPTION_PWD = $WALLET_PASSWORD
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --usebtcfastsync
        } catch {
            LogMessage "Error occurred during basicswap-prepare execution: $_"
            exit 1
        }

        LogMessage "[INFO] BasicSwap setup completed."
    }
} catch {
    LogMessage "Error occurred during initial setup steps: $_"
    exit 1
}

try {
    LogMessage "[INFO] Setup and installation completed."
    exit 0
} catch {
    LogMessage "Error occurred during subsequent steps: $_"
    exit 1
}

# Clean up the temporary configuration file
Remove-Item $configPath
