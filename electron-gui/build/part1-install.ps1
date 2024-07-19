# Requires -Version 5.0
# part1-install.ps1

param (
    [string]$INSTALL_PATH,
    [string]$SELECTED_COINS,
    [string]$WALLET_PASSWORD
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

LogMessage "##############################################################################"
LogMessage "# Check if running as administrator."
LogMessage "##############################################################################"

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    LogMessage "##############################################################################"
    LogMessage "# Please right-click and re-run installer as administrator."
    LogMessage "##############################################################################"
    exit 1
}

function Uninstall-Dependencies-Windows {
    LogMessage "[INFO] Uninstalling dependencies..."

    $dependencies = @('python3', 'protoc', 'curl', 'jq', 'wget', 'gnupg', 'git')

    foreach ($dep in $dependencies) {
        if (choco list --local-only $dep | Where-Object { $_ -match "$dep\|" }) {
            LogMessage "[INFO] Uninstalling $dep..." "INFO"
            try {
                choco uninstall $dep -y
            } catch {
                LogMessage "Failed to uninstall ${dep}: $_"
            }
        } else {
            LogMessage "[INFO] $dep not found, skipping..."
        }
    }

    LogMessage "[INFO] Finished uninstalling dependencies."
}

function Install-Dependencies-Windows {
    LogMessage "[INFO] Installing required dependencies..."
    LogMessage "PROGRESS: 5" "INFO"

    # Check if Chocolatey is installed
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        # Check for the existence of the Chocolatey directory and remove if found
        if (Test-Path "$env:ChocolateyInstall") {
            Remove-Item -Recurse -Force "$env:ChocolateyInstall"
        }

        LogMessage "[INFO] Chocolatey not found. Installing Chocolatey..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force;
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        } catch {
            LogMessage "Failed to install Chocolatey: $_"
            return
        }
    } else {
        LogMessage "[INFO] Chocolatey already installed."
    }

    # Check if older versions of Python exist and remove them
    LogMessage "[INFO] Check if older versions of Python exist and remove them"
    if (choco list --local-only python | Where-Object { $_ -match 'python\|' }) {
        LogMessage "[INFO] Removing older versions of Python..." "INFO"
        try {
            choco uninstall python -y
        } catch {
            LogMessage "Failed to uninstall older versions of Python: $_"
        }
    }

    # Install required packages via Chocolatey
    LogMessage "[INFO] Installing python, protoc, curl, jq, wget, gnupg, git via Chocolatey..."
    try {
        $chocoOutput = choco install python3 protoc curl jq wget gnupg git protobuf -y 2>&1
        LogMessage $chocoOutput "INFO"
    } catch {
        LogMessage "Failed to install dependencies via Chocolatey: $_"
        return
    }

    LogMessage "PROGRESS: 10"
}

LogMessage "##############################################################################"
LogMessage "# 0 Uninstall Dependencies."
LogMessage "##############################################################################"

Uninstall-Dependencies-Windows

LogMessage "##############################################################################"
LogMessage "# 1 Installing Dependencies."
LogMessage "##############################################################################"

Install-Dependencies-Windows

# Create a Python Virtual Environment
LogMessage "[INFO] Creating a Python virtual environment..."
$venvPath = Join-Path -Path $INSTALL_PATH -ChildPath "venv"
python -m venv $venvPath

# Activate the Virtual Environment
LogMessage "[INFO] Activating the virtual environment..."
$activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate"
. $activateScript
LogMessage "[INFO] Virtual environment activated!"

Write-Host "##############################################################################"
Write-Host "# 2 Start of script."
Write-Host "##############################################################################"

LogMessage "[INFO] Checking and installing prerequisites..."
LogMessage "[INFO] INSTALL_PATH: $INSTALL_PATH"
LogMessage "[INFO] SELECTED_COINS: $SELECTED_COINS"
LogMessage "PROGRESS: 15"

Write-Host "##############################################################################"
Write-Host "# 3 User selected installation path and selected coins."
Write-Host "##############################################################################"

LogMessage "[INFO] Please enter the absolute path to the directory where you wish to install BasicSwap: $INSTALL_PATH"
LogMessage "[INFO] Please choose the coins you want to include (separate with commas, no spaces): $SELECTED_COINS"
LogMessage "PROGRESS: 20"

Write-Host "##############################################################################"
Write-Host "# 4 Validate selected coins input"
Write-Host "##############################################################################"

LogMessage "[INFO] Validating selected coins input."

if ($SELECTED_COINS -notmatch '^[a-zA-Z,]+$') {
    LogMessage "Invalid input. Please only use comma-separated coin names without spaces." "ERROR"
    exit 1
}

LogMessage "Selected coins input validated successfully."


Write-Host "##############################################################################"
Write-Host "# 5 Set up the coins data directory."
Write-Host "##############################################################################"

LogMessage "[INFO] Setting up the coins data directory..."

$COINDATA_PATH = Join-Path $INSTALL_PATH "coindata"
LogMessage "[INFO] The path to the coins data dirs folder is $COINDATA_PATH"
LogMessage "PROGRESS: 25"

Write-Host "##############################################################################"
Write-Host "# 6 Check if the coins data directory exists."
Write-Host "##############################################################################"

LogMessage "[INFO] Checking if the coins data directory exists..."

if (Test-Path $COINDATA_PATH) {
    LogMessage "The coins data directory already exists at $COINDATA_PATH." "WARNING"
    $response = Read-Host "Would you like to perform a fresh installation and remove the existing directory? (y/N)"
    if ($response -match "^(y|yes)$") {
        LogMessage "[INFO] Removing coins data directory to start a fresh installation..."
        Remove-Item $COINDATA_PATH -Recurse -Force
    }
}

LogMessage "PROGRESS: 30"
New-Item -ItemType Directory -Force -Path $COINDATA_PATH
LogMessage "PROGRESS: 35"

Write-Host "##############################################################################"
Write-Host "# 7 Check if Python is installed, and if not, install required dependencies."
Write-Host "##############################################################################"

LogMessage "[INFO] Checking if Python is installed..."

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    LogMessage "[ERROR] Python is not installed. Attempting to install required dependencies..."
    Install-Dependencies-Windows
} else {
    LogMessage "[INFO] Python detected: $(python --version)"
}

LogMessage "PROGRESS: 40"

$COINCURVE_REPO_PATH = Join-Path $COINDATA_PATH "coincurve-tecnovert"

$config = @{
    INSTALL_PATH = $INSTALL_PATH
    SELECTED_COINS = $SELECTED_COINS
    WALLET_PASSWORD =$WALLET_PASSWORD
}
$configPath = Join-Path $env:TEMP "basicswap_config.json"
$config | ConvertTo-Json | Set-Content $configPath

Write-Host "##############################################################################"
Write-Host "# Part 1 completed. Running Part 2"
Write-Host "##############################################################################"