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

function Create-BatFiles {
    $INSTALL_PATH_RUN = $INSTALL_PATH

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

    $runBatPath = Join-Path -Path $INSTALL_PATH -ChildPath "Start_BasicSwapDEX_Run_As_Administrator.bat"
    $runBatContent | Set-Content -Path $runBatPath

    $updateBatContent = @"
REM Set the swap directory
set "SWAP_DATADIR=$INSTALL_PATH"

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
git clone https://github.com/basicswap/basicswap.git

REM Change directory to basicswap directory
cd "%SWAP_DATADIR%\basicswap"

REM Pull latest basicswap version from github
git pull

REM Install latest version
pip3 install .

REM You can close command-line windows now with CTRL+C and start update.bat
pause
"@

    $updateBatPath = Join-Path -Path $INSTALL_PATH -ChildPath "Update_BasicSwapDEX_and_Coincurve_Run_As_Administrator.bat"
    $updateBatContent | Set-Content -Path $updateBatPath

    LogMessage "[INFO] Created Start_BasicSwapDEX_Run_As_Administrator.bat and Update_BasicSwapDEX_and_Coincurve_Run_As_Administrator.bat"
}

function Uninstall-Dependencies-Windows {
    LogMessage "[INFO] Uninstalling dependencies..."

    $dependencies = @('python3', 'protoc', 'curl', 'jq', 'wget', 'gnupg', 'git')

    foreach ($dep in $dependencies) {
        if (choco list --local-only $dep | Where-Object { $_ -match "$dep\|" }) {
            LogMessage "[INFO] Uninstalling $dep..."
            try {
                choco uninstall $dep -y
            } catch {
                LogMessage "Failed to uninstall ${dep}: $_" "ERROR"
            }
        } else {
            LogMessage "[INFO] $dep not found, skipping..."
        }
    }

    LogMessage "[INFO] Finished uninstalling dependencies."
}

function Install-Dependencies-Windows {
    LogMessage "[INFO] Installing required dependencies..."
    LogMessage "PROGRESS: 5"

    # Check if Chocolatey is installed
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        if (Test-Path "$env:ChocolateyInstall") {
            Remove-Item -Recurse -Force "$env:ChocolateyInstall"
        }

        LogMessage "[INFO] Chocolatey not found. Installing Chocolatey..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        } catch {
            LogMessage "Failed to install Chocolatey: $_" "ERROR"
            return
        }
    } else {
        LogMessage "[INFO] Chocolatey already installed."
    }

    # Install required packages via Chocolatey
    LogMessage "[INFO] Installing python, protoc, curl, jq, wget, gnupg, git, via Chocolatey..."
    try {
        $chocoOutput = choco install python3 protoc curl jq wget gnupg git protobuf -y 2>&1
        LogMessage $chocoOutput

        RefreshEnv
    } catch {
        LogMessage "Failed to install dependencies via Chocolatey: $_" "ERROR"
        return
    }

    # Verify GPG installation
    if (-not (Get-Command gpg -ErrorAction SilentlyContinue)) {
        LogMessage "GPG installation failed or not in PATH" "ERROR"
        exit 1
    }

    LogMessage "PROGRESS: 10"
}

# Main script execution starts here

LogMessage "##############################################################################"
LogMessage "# Check if running as administrator."
LogMessage "##############################################################################"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    LogMessage "Please right-click and re-run installer as administrator." "ERROR"
    exit 1
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
$activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"
. $activateScript
LogMessage "[INFO] Virtual environment activated!"

LogMessage "##############################################################################"
LogMessage "# 2 Start of script."
LogMessage "##############################################################################"

LogMessage "[INFO] Checking and installing prerequisites..."
LogMessage "[INFO] INSTALL_PATH: $INSTALL_PATH"
LogMessage "[INFO] SELECTED_COINS: $SELECTED_COINS"
LogMessage "PROGRESS: 15"

LogMessage "##############################################################################"
LogMessage "# 3 User selected installation path and selected coins."
LogMessage "##############################################################################"

LogMessage "[INFO] Please enter the absolute path to the directory where you wish to install BasicSwap: $INSTALL_PATH"
LogMessage "[INFO] Please choose the coins you want to include (separate with commas, no spaces): $SELECTED_COINS"
LogMessage "PROGRESS: 20"

LogMessage "##############################################################################"
LogMessage "# 4 Validate selected coins input"
LogMessage "##############################################################################"

if ($SELECTED_COINS -notmatch '^[a-zA-Z,]+$') {
    LogMessage "Invalid input. Please only use comma-separated coin names without spaces." "ERROR"
    exit 1
}

LogMessage "Selected coins input validated successfully."

LogMessage "##############################################################################"
LogMessage "# 5 Set up the coins data directory."
LogMessage "##############################################################################"

$COINDATA_PATH = Join-Path $INSTALL_PATH "coindata"
LogMessage "[INFO] The path to the coins data dirs folder is $COINDATA_PATH"
LogMessage "PROGRESS: 25"

LogMessage "##############################################################################"
LogMessage "# 6 Check if the coins data directory exists."
LogMessage "##############################################################################"

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

LogMessage "##############################################################################"
LogMessage "# 7 Check if Python is installed, and if not, install required dependencies."
LogMessage "##############################################################################"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    LogMessage "[ERROR] Python is not installed. Attempting to install required dependencies..."
    Install-Dependencies-Windows
} else {
    LogMessage "[INFO] Python detected: $(python --version)"
}

LogMessage "##############################################################################"
LogMessage "# 8 Create .bat files"
LogMessage "##############################################################################"

Create-BatFiles

LogMessage "PROGRESS: 40"

$COINCURVE_REPO_PATH = Join-Path $COINDATA_PATH "coincurve-tecnovert"

$config = @{
    INSTALL_PATH = $INSTALL_PATH
    SELECTED_COINS = $SELECTED_COINS
    WALLET_PASSWORD = $WALLET_PASSWORD
}
$configPath = Join-Path $env:TEMP "basicswap_config.json"
$config | ConvertTo-Json | Set-Content $configPath

LogMessage "##############################################################################"
LogMessage "# Part 1 completed. Running Part 2"
LogMessage "##############################################################################"