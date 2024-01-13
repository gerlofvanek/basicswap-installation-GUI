# Requires -Version 5.0

param (
    [string]$INSTALL_PATH,
    [string]$SELECTED_COINS
)

function LogMessage {
    param(
        [string]$message,
        [string]$type
    )

    # Add logging logic here
    if ($type -eq "ERROR") {
        Write-Error $message

    } else {
        Write-Host $message
    }
}

######################################
# Start_BasicSwapDEX.bat
######################################

$INSTALL_PATH_RUN = "$INSTALL_PATH"

$runBatContent = @"
REM Navigate to the directory where BasicSwap DEX is located
cd /d "$INSTALL_PATH_RUN"

REM Set up directories and environment for BasicSwap DEX
set "SWAP_DATADIR=$INSTALL_PATH_RUN"
mkdir "%SWAP_DATADIR%\venv"
python -m venv "%SWAP_DATADIR%\venv"

REM Activate the Python virtual environment and update Command Prompt title
call "%SWAP_DATADIR%\venv\Scripts\activate" && title Command Prompt (venv)

REM Wait for a few seconds to ensure the virtual environment is activated
timeout /t 5 >nul

REM Check the Python version (optional, for verification)
python -V

REM Navigate to the BasicSwap directory and start the DEX
cd "$INSTALL_PATH\basicswap"
basicswap-run --datadir="$INSTALL_PATH\coindata"

REM Display instructions for accessing BasicSwap in a web browser
echo After a few minutes, you can launch your preferred web browser and enter the following into the address bar:
echo http://localhost:12700 or http://127.0.0.1:12700
"@

# Path for the run.bat file
$runBatPath = Join-Path -Path $INSTALL_PATH -ChildPath "Start_BasicSwapDEX_Run_As_Administrator.bat"

# Create or overwrite the run.bat file with the provided content
$runBatContent | Set-Content -Path $runBatPath

######################################
# Batch script block ends here
######################################

######################################
# Update_BasicSwapDEX_and_Coincurve.bat
######################################

$INSTALL_PATH_UPDATE = "$INSTALL_PATH"

$updateBatContent = @"
REM Set the swap directory
set "SWAP_DATADIR=$INSTALL_PATH_UPDATE"

REM Remove the existing coincurve-anonswap directory if it exists
if exist "%SWAP_DATADIR%\coindata\coincurve-tecnovert" rmdir /s /q "%SWAP_DATADIR%\coindata\coincurve-tecnovert"

REM Remove the existing basicswap directory if it exists
if exist "%SWAP_DATADIR%\basicswap" rmdir /s /q "%SWAP_DATADIR%\basicswap"

REM Create the venv directory
mkdir "%SWAP_DATADIR%\venv"

REM Activate the Python virtual environment and update Command Prompt title
call "%SWAP_DATADIR%\venv\Scripts\activate" && title Command Prompt (venv)

REM Wait for a few seconds to ensure the virtual environment is activated
timeout /t 5 >nul

REM Check the Python version (optional, for verification)
python -V

REM Change directory to the swap directory
cd /d "%SWAP_DATADIR%"

REM Download coincurve-anonswap zip file from GitHub
git clone -b bsx_windows https://github.com/tecnovert/coincurve.git coindata\coincurve-tecnovert

cd "%SWAP_DATADIR%\coindata\coincurve-tecnovert"

python -m pip install .

REM Change directory back to the swap directory
cd "%SWAP_DATADIR%"

REM Clone basicswap repository from GitHub
git clone https://github.com/tecnovert/basicswap.git

REM Change directory to basicswap directory
cd "%SWAP_DATADIR%\basicswap"

REM Pull latest basicswap version from github
git pull

REM Install latest version
pip3 install .

REM You can close command-line windows now with CTRL+C and start update.bat
pause
"@

# Path for the update.bat file
$updateBatPath = Join-Path -Path $INSTALL_PATH -ChildPath "Update_BasicSwapDEX_and_Coincurve_Run_As_Administrator.bat"

# Create or overwrite the update.bat file with the provided content
$updateBatContent | Set-Content -Path $updateBatPath

######################################
# Batch script block ends here
######################################

LogMessage "" "INFO"
LogMessage "##############################################################################" "INFO"
LogMessage "# Check if running as administrator." "INFO"
LogMessage "##############################################################################" "INFO"
LogMessage ""

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    LogMessage "##############################################################################" "INFO"
    LogMessage "# Please right-click and re-run installer as administrator." "ERROR"
    LogMessage "##############################################################################" "INFO"
    exit 1
}

function Uninstall-Dependencies-Windows {
    LogMessage "[INFO] Uninstalling dependencies..." "INFO"

    $dependencies = @('python3', 'protoc', 'curl', 'jq', 'wget', 'gnupg', 'git', 'protobuf')

    foreach ($dep in $dependencies) {
        if (choco list --local-only $dep | Where-Object { $_ -match "$dep\|" }) {
            LogMessage "[INFO] Uninstalling $dep..." "INFO"
            try {
                choco uninstall $dep -y
            } catch {
                LogMessage "Failed to uninstall ${dep}: $_" "ERROR"
            }
        } else {
            LogMessage "[INFO] $dep not found, skipping..." "INFO"
        }
    }

    LogMessage "[INFO] Finished uninstalling dependencies." "INFO"
}

function Install-Dependencies-Windows {
    LogMessage "[INFO] Installing required dependencies..." "INFO"
    LogMessage "PROGRESS: 5" "INFO"

    # Check if Chocolatey is installed    
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        # Check for the existence of the Chocolatey directory and remove if found
        if (Test-Path "$env:ChocolateyInstall") {
            Remove-Item -Recurse -Force "$env:ChocolateyInstall"
        }

        LogMessage "[INFO] Chocolatey not found. Installing Chocolatey..." "INFO"
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force;
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        } catch {
            LogMessage "Failed to install Chocolatey: $_" "ERROR"
            return
        }
    } else {
        LogMessage "[INFO] Chocolatey already installed." "INFO"
    }

    # Check if older versions of Python exist and remove them
    LogMessage "[INFO] Check if older versions of Python exist and remove them" "INFO"
    if (choco list --local-only python | Where-Object { $_ -match 'python\|' }) {
        LogMessage "[INFO] Removing older versions of Python..." "INFO"
        try {
            choco uninstall python -y
        } catch {
            LogMessage "Failed to uninstall older versions of Python: $_" "ERROR"
        }
    }

    # Install required packages via Chocolatey
    LogMessage "[INFO] Installing python, protoc, protobuf, curl, jq, wget, gnupg, git via Chocolatey..." "INFO"
    try {
        $chocoOutput = choco install python3 protoc curl jq wget gnupg git protobuf -y 2>&1
        LogMessage $chocoOutput "INFO"
    } catch {
        LogMessage "Failed to install dependencies via Chocolatey: $_" "ERROR"
        return
    }

    LogMessage "PROGRESS: 10" "INFO"
}

# Call the functions
LogMessage "" "INFO"
LogMessage "##############################################################################" "INFO"
LogMessage "# 0 Uninstall Dependencies." "INFO"
LogMessage "##############################################################################" "INFO"
LogMessage ""

Uninstall-Dependencies-Windows

LogMessage "" "INFO"
LogMessage "##############################################################################" "INFO"
LogMessage "# 1 Installing Dependencies." "INFO"
LogMessage "##############################################################################" "INFO"
LogMessage ""

Install-Dependencies-Windows

# Create a Python Virtual Environment
LogMessage "[INFO] Creating a Python virtual environment..." "INFO"
$venvPath = Join-Path -Path $INSTALL_PATH -ChildPath "venv"
python -m venv $venvPath

# Activate the Virtual Environment
LogMessage "[INFO] Activating the virtual environment..." "INFO"
$activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate"
. $activateScript
LogMessage "[INFO] Virtual environment activated!" "INFO"


Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 2 Start of script."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Checking and installing prerequisites..." "INFO"
LogMessage "[INFO] INSTALL_PATH: $INSTALL_PATH" "INFO"
LogMessage "[INFO] SELECTED_COINS: $SELECTED_COINS" "INFO"
LogMessage "PROGRESS: 15" "INFO"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 3 User selected installation path and selected coins."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Please enter the absolute path to the directory where you wish to install BasicSwap: $INSTALL_PATH" "INFO"
LogMessage "[INFO] Please choose the coins you want to include (separate with commas, no spaces): $SELECTED_COINS" "INFO"
LogMessage "PROGRESS: 20" "INFO"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 4 Validate selected coins input"
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Validating selected coins input." "INFO"

if ($SELECTED_COINS -notmatch '^[a-zA-Z,]+$') {
    LogMessage "Invalid input. Please only use comma-separated coin names without spaces." "ERROR"
    exit 1
}

LogMessage "Selected coins input validated successfully." "INFO"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 5 Set up the coins data directory."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Setting up the coins data directory..." "INFO"

$COINDATA_PATH = Join-Path $INSTALL_PATH "coindata"
LogMessage "[INFO] The path to the coins data dirs folder is $COINDATA_PATH" "INFO"
LogMessage "PROGRESS: 25" "INFO"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 6 Check if the coins data directory exists."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Checking if the coins data directory exists..." "INFO"

if (Test-Path $COINDATA_PATH) {
    LogMessage "The coins data directory already exists at $COINDATA_PATH." "WARNING"
    $response = Read-Host "Would you like to perform a fresh installation and remove the existing directory? (y/N)"
    if ($response -match "^(y|yes)$") {
        LogMessage "[INFO] Removing coins data directory to start a fresh installation..." "INFO"
        Remove-Item $COINDATA_PATH -Recurse -Force
    }
}

LogMessage "PROGRESS: 30" "INFO"
New-Item -ItemType Directory -Force -Path $COINDATA_PATH
LogMessage "PROGRESS: 35" "INFO"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 7 Check if Python is installed, and if not, install required dependencies."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Checking if Python is installed..." "INFO"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    LogMessage "[ERROR] Python is not installed. Attempting to install required dependencies..." "ERROR"
    Install-Dependencies-Windows
} else {
    LogMessage "[INFO] Python detected: $(python --version)" "INFO"
}

LogMessage "PROGRESS: 40" "INFO"

$COINCURVE_REPO_PATH = Join-Path $COINDATA_PATH "coincurve-tecnovert"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 8 Set up Python virtual environment."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Setting up Python virtual environment..." "INFO"

# Create a Python Virtual Environment if it doesn't exist
if (-not (Test-Path $venvPath)) {
    LogMessage "[INFO] Python virtual environment does not exist. Creating..." "INFO"
    python -m venv $venvPath
} else {
    LogMessage "[INFO] Python virtual environment already exists." "INFO"
}

# Activate the Virtual Environment
LogMessage "[INFO] Activating the virtual environment..." "INFO"
$activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate"
. $activateScript
LogMessage "[INFO] Virtual environment activated!" "INFO"
LogMessage "PROGRESS: 40" "INFO"

$COINCURVE_REPO_PATH = Join-Path $COINDATA_PATH "coincurve-tecnovert"

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 9 Check if Git is installed."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Checking if Git is installed..." "INFO"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    LogMessage "[ERROR] Git is not installed. Please ensure Git is installed before proceeding." "ERROR"
    exit 1
} else {
    LogMessage "[INFO] Git detected." "INFO"
    LogMessage "PROGRESS: 45" "INFO"
}

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 10 Cloning and setting up coincurve from tecnovert's GitHub fork."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Cloning and setting up coincurve from tecnovert's GitHub fork..." "INFO"

try {
    git clone -b bsx_windows https://github.com/tecnovert/coincurve.git $COINCURVE_REPO_PATH
    Set-Location -Path $COINCURVE_REPO_PATH
    python -m pip install .
    LogMessage "[INFO] Successfully installed coincurve from tecnovert's fork." "INFO"
    LogMessage "PROGRESS: 50" "INFO"
} catch {
    LogMessage "Error occurred during coincurve setup. Please ensure you have proper network access and permissions: $_" "ERROR"
    exit 1
}

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 11 Cloning and setting up BasicSwap from GitHub."
Write-Host "##############################################################################"
Write-Host ""

$BASICSWAP_PATH = Join-Path $INSTALL_PATH "basicswap"

LogMessage "[INFO] Cloning and setting up BasicSwap from GitHub..." "INFO"

try {
    git clone https://github.com/tecnovert/basicswap.git $BASICSWAP_PATH
    Set-Location -Path $BASICSWAP_PATH
    protoc -I=basicswap --python_out=basicswap basicswap/messages.proto
    LogMessage "[INFO] Installing required Python packages for BasicSwap..." "INFO"
    pip install protobuf==3.20.*
    pip install .
    LogMessage "PROGRESS: 60" "INFO"
} catch {
    LogMessage "Error occurred during BasicSwap setup. Please ensure you have proper network access and permissions: $_" "ERROR"
    exit 1
}

Write-Host ""
Write-Host "##############################################################################"
Write-Host "# 12 Preparing Basicswap."
Write-Host "##############################################################################"
Write-Host ""

LogMessage "[INFO] Preparing BasicSwap..." "INFO"

try {
    if ($SELECTED_COINS.Contains("Monero")) {
        LogMessage "[INFO] Preparing Monero setup. Fetching current XMR height..." "INFO"
        $CURRENT_XMR_HEIGHT = (Invoke-WebRequest -Uri "https://localmonero.co/blocks/api/get_stats" | ConvertFrom-Json).height
        LogMessage "[INFO] Monero selected. Current XMR height: $CURRENT_XMR_HEIGHT" "INFO"
        LogMessage "PROGRESS: 70" "INFO"
        LogMessage "[INFO] Starting basicswap-prepare for Monero. This might take a while.." "INFO"
        
        try {
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --xmrrestoreheight=$CURRENT_XMR_HEIGHT --usebtcfastsync
        } catch {
            LogMessage "Error occurred during basicswap-prepare execution for Monero: $_" "ERROR"
            exit 1
        }
        
        LogMessage "[INFO] BasicSwap with Monero setup and download completed." "INFO"
    } else {
        LogMessage "[INFO] Preparing BasicSwap." "INFO"
        LogMessage "PROGRESS: 70" "INFO"
        LogMessage "[INFO] Starting basicswap-prepare. This might take a while..." "INFO"
        
        try {
            basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --usebtcfastsync
        } catch {
            LogMessage "Error occurred during basicswap-prepare execution: $_" "ERROR"
            exit 1
        }
        
        LogMessage "[INFO] BasicSwap setup completed." "INFO"
    }
} catch {
    LogMessage "Error occurred during initial setup steps: $_" "ERROR"
    exit 1
}

try {
    LogMessage "[INFO] Setup and installation completed." "INFO"
    exit 0
} catch {
    LogMessage "Error occurred during subsequent steps: $_" "ERROR"
    exit 1
}