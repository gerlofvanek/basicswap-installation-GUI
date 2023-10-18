# Requires -Version 5.0

param (
    [string]$INSTALL_PATH,
    [string]$SELECTED_COINS
)

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "##############################################################################"
    Write-Error "Please right-click and re-run installer as administrator."
    Write-Host "##############################################################################"
    exit 1
}

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 1 Installing Dependencies."
Write-Host "##############################################################################"
Write-Host ""

function Install-Dependencies-Windows {
    Write-Host "[INFO] Installing required dependencies..."
    Write-Host "PROGRESS: 5"

    # Check if Chocolatey is installed    
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        # Check for the existence of the Chocolatey directory and remove if found
        if (Test-Path "$env:ChocolateyInstall") {
            Remove-Item -Recurse -Force "$env:ChocolateyInstall"
        }

        Write-Host "[INFO] Chocolatey not found. Installing Chocolatey..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force;
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        } catch {
            Write-Error "Failed to install Chocolatey: $_"
            return
        }
    } else {
        Write-Host "[INFO] Chocolatey already installed."
    }

    # Check if older versions of Python exist and remove them
    Write-Host "[INFO] Check if older versions of Python exist and remove them"
    if (choco list --local-only python | Where-Object { $_ -match 'python\|' }) {
        Write-Host "[INFO] Removing older versions of Python..."
        try {
            choco uninstall python -y
        } catch {
            Write-Error "Failed to uninstall older versions of Python: $_"
        }
    }

    # Install required packages via Chocolatey
    Write-Host "[INFO] Installing python, protoc, protobuf, curl, jq, wget, gnupg, git via Chocolatey..."
    try {
        $chocoOutput = choco install python3 protoc protobuf curl jq wget gnupg git -y 2>&1
        Write-Host $chocoOutput
    } catch {
        Write-Error "Failed to install dependencies via Chocolatey: $_"
        return
    }

    Write-Host "PROGRESS: 10"
}

Install-Dependencies-Windows

# Create a Python Virtual Environment
Write-Host "[INFO] Creating a Python virtual environment..."
$venvPath = Join-Path -Path $INSTALL_PATH -ChildPath "venv"
python -m venv $venvPath

# Activate the Virtual Environment
Write-Host "[INFO] Activating the virtual environment..."
$activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate"
. $activateScript

Write-Host "[INFO] Virtual environment activated!"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 2 Start of script."
Write-Host "##############################################################################"
Write-Host ""

Write-Host "[INFO] Checking and installing prerequisites..."
Write-Host "[INFO] INSTALL_PATH: $INSTALL_PATH"
Write-Host "[INFO] SELECTED_COINS: $SELECTED_COINS"
Write-Host "PROGRESS: 15"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 3 User input for installation path and selected coins."
Write-Host "##############################################################################"
Write-Host ""

Write-Host "[INFO] Please enter the absolute path to the directory where you wish to install BasicSwap: $INSTALL_PATH"
Write-Host "[INFO] Please choose the coins you want to include (separate with commas, no spaces): $SELECTED_COINS"
Write-Host "PROGRESS: 20"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 4 Validate selected coins input"
Write-Host "##############################################################################"
Write-Host ""

if ($SELECTED_COINS -notmatch '^[a-zA-Z,]+$') {
    Write-Error "Invalid input. Please only use comma-separated coin names without spaces."
    exit 1
}

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 5 Set up the coins data directory."
Write-Host "##############################################################################"
Write-Host ""

$COINDATA_PATH = Join-Path $INSTALL_PATH "coindata"
Write-Host "[INFO] The path to the coins data dirs folder is $COINDATA_PATH"
Write-Host "PROGRESS: 25"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 6 Check if the coins data directory exists and offer to remove it."
Write-Host "##############################################################################"
Write-Host ""

if (Test-Path $COINDATA_PATH) {
    Write-Warning "The coins data directory already exists at $COINDATA_PATH."
    $response = Read-Host "Would you like to perform a fresh installation and remove the existing directory? (y/N)"
    if ($response -match "^(y|yes)$") {
        Write-Host "[INFO] Removing coins data dir folder to start a fresh installation..."
        Remove-Item $COINDATA_PATH -Recurse -Force
    }
}

Write-Host "PROGRESS: 30"
New-Item -ItemType Directory -Force -Path $COINDATA_PATH
$VENV_PATH = Join-Path $INSTALL_PATH "basicswap_venv"
Write-Host "PROGRESS: 35"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 7 Check if Python is installed, and if not, install required dependencies."
Write-Host "##############################################################################"
Write-Host ""

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Python is not installed. Now attempting to install required dependencies..."
    Install-Dependencies-Windows
} else {
    Write-Host "[INFO] Python detected: $(python --version)"
}


Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 8 Set up Python virtual environment."
Write-Host "##############################################################################"
Write-Host ""

python -m venv $VENV_PATH
$ENV_PATH = Join-Path $VENV_PATH "Scripts"
$activate = Join-Path $ENV_PATH "Activate"
. $activate
Write-Host "[INFO] Virtual environment set up with $(python --version)"
Write-Host "PROGRESS: 40"

$COINCURVE_REPO_PATH = Join-Path $COINDATA_PATH "coincurve-tecnovert"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 9 Check if Git is installed."
Write-Host "##############################################################################"
Write-Host ""

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Git is not installed. Please ensure Git is installed before proceeding."
    exit 1
} else {
    Write-Host "[INFO] Git detected."
    Write-Host "PROGRESS: 45"
}


Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 10 Cloning and setting up coincurve from tecnovert's GitHub fork."
Write-Host "##############################################################################"
Write-Host ""

try {
    Write-Host "[INFO] Cloning and setting up coincurve from tecnovert's GitHub fork..."
    git clone -b bsx_windows https://github.com/tecnovert/coincurve.git $COINCURVE_REPO_PATH
    Set-Location -Path $COINCURVE_REPO_PATH
    python -m pip install .
    Write-Host "[INFO] Successfully installed coincurve from tecnovert's fork."
    Write-Host "PROGRESS: 50"
} catch {
    Write-Error "Error occurred during coincurve setup. Please ensure you have proper network access and permissions: $_"
    exit 1
}

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 11 Cloning and setting up BasicSwap from GitHub."
Write-Host "##############################################################################"
Write-Host ""

$BASICSWAP_PATH = Join-Path $INSTALL_PATH "basicswap"

try {
    Write-Host "[INFO] Cloning and setting up BasicSwap from GitHub..."
    git clone https://github.com/tecnovert/basicswap.git $BASICSWAP_PATH
    cd $BASICSWAP_PATH
    protoc -I=basicswap --python_out=basicswap basicswap/messages.proto
    Write-Host "[INFO] Installing required Python packages for BasicSwap..."
    pip install protobuf==3.20.*
    pip install .
    Write-Host "PROGRESS: 60"
} catch {
    Write-Error "Error occurred during BasicSwap setup. Please ensure you have proper network access and permissions: $_"
    exit 1
}

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 12 Preparing Basicswap."
Write-Host "##############################################################################"
Write-Host ""

try {
    if ($SELECTED_COINS.Contains("Monero")) {
        Write-Host "[INFO] Preparing Monero setup. Fetching current XMR height..."
        $CURRENT_XMR_HEIGHT = (Invoke-WebRequest -Uri "https://localmonero.co/blocks/api/get_stats" | ConvertFrom-Json).height
        Write-Host "[INFO] Monero selected. Current XMR height: $CURRENT_XMR_HEIGHT"
        Write-Host "PROGRESS: 70"
        Write-Host "[INFO] Starting basicswap-prepare for Monero. This might take a while.." .
        
        try {
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --xmrrestoreheight=$CURRENT_XMR_HEIGHT --usebtcfastsync
        } catch {
            Write-Error "Error occurred during basicswap-prepare execution for Monero: $_"
            exit 1
        }
        
        Write-Host "[INFO] BasicSwap with Monero setup and download completed."

    } else {
        Write-Host "[INFO] Preparing BasicSwap."
        Write-Host "PROGRESS: 70"
        Write-Host "[INFO] Starting basicswap-prepare. This might take a while..."
        
        try {
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --usebtcfastsync
        } catch {
            Write-Error "Error occurred during basicswap-prepare execution: $_"
            exit 1
        }
        
        Write-Host "[INFO] BasicSwap setup completed."
    }
} catch {
    Write-Error "Error occurred during initial setup steps: $_"
    exit 1
}

try {
    # Rest of the script's logic after basicswap-prepare
    Write-Host "[INFO] Setup and installation completed."
    exit 0
} catch {
    Write-Error "Error occurred during subsequent steps: $_"
    exit 1
}