#!/bin/bash
set -e

function install_dependencies_macos() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install python3 gnupg protobuf automake libtool pkg-config curl jq git wget
}

echo "Checking and installing prerequisites..."

# Check the OS and install dependencies accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macOS detected"
    install_dependencies_macos
else
    echo "This script is for macOS only. Please use the Linux script if you are on a Linux system."
    exit 1
fi

echo "Please enter the absolute path to the directory where you wish to install BasicSwap:"
read INSTALL_PATH

# Prompt the user for the coins they want to include
echo "Please choose the coins you want to include (separate with commas, no spaces):"
echo "Options: monero, bitcoin, litecoin, dash, pivx, firo"
read SELECTED_COINS

# Verify the user's input
if ! [[ "$SELECTED_COINS" =~ ^[a-zA-Z,]+$ ]]; then
    echo "Invalid input. Please only use comma-separated coin names without spaces."
    exit 1
fi

# Set the location where the local nodes for the coins that will be included in BasicSwap will be installed
COINDATA_PATH=$INSTALL_PATH/coindata
echo "The path to the coins data dirs folder is $COINDATA_PATH"

# Set a custom URL for the BTC fast-sync file
export BITCOIN_FASTSYNC_URL="https://eu2.contabostorage.com/1f50a74c9dc14888a8664415dad3d020:utxosets/"
export BITCOIN_FASTSYNC_FILE="utxo-snapshot-bitcoin-mainnet-769818.tar"

# Check if the coins data directory exists and ask the user if they want to do a fresh installation
if [ -d "$COINDATA_PATH" ]; then
    echo "The coins data directory already exists at $COINDATA_PATH."
    read -p "Would you like to perform a fresh installation and remove the existing directory? (y/N): " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Removing coins data dir folder to start a fresh installation..."
        rm -R -f $COINDATA_PATH
    fi
fi

echo "Creating coins data dir"
mkdir -p $COINDATA_PATH

cd $COINDATA_PATH

echo "Creating Python virtual environment"
mkdir -p "$INSTALL_PATH/basicswap_venv"
python3 -m venv "$INSTALL_PATH/basicswap_venv"

source "$INSTALL_PATH/basicswap_venv/bin/activate"
echo "The virtual environment uses $(python -V)"

echo "Fetching the coincurve library"
rm -R -f $COINDATA_PATH/coincurve-anonswap
wget https://github.com/tecnovert/coincurve/archive/refs/tags/anonswap_v0.1.tar.gz
tar -xf anonswap_v0.1.tar.gz
mv ./coincurve-anonswap_v0.1 ./coincurve-anonswap

echo "Building and installing the Coincurve library"
cd $COINDATA_PATH/coincurve-anonswap
pip3 install .

echo "Cloning the Basic Swap DEX repo"
rm -R -f $INSTALL_PATH/basicswap
cd $INSTALL_PATH
git clone https://github.com/tecnovert/basicswap.git

echo "Building and installing the Basic Swap DEX"
cd $INSTALL_PATH/basicswap
protoc -I=basicswap --python_out=basicswap basicswap/messages.proto
pip3 install protobuf==3.20.*
pip3 install .

echo "Initializing the coins data directory $COINDATA_PATH"

if [[ "$SELECTED_COINS" == *monero* ]]; then
    CURRENT_XMR_HEIGHT=$(curl https://localmonero.co/blocks/api/get_stats | jq .height)
    basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --xmrrestoreheight=$CURRENT_XMR_HEIGHT --usebtcfastsync
else
    CURRENT_XMR_HEIGHT="0"
    basicswap-prepare --datadir=$COINDATA_PATH --withcoins=$SELECTED_COINS --usebtcfastsync
fi

echo "To start the Basic Swap DEX, run the command below:"
echo "source $INSTALL_PATH/basicswap_venv/bin/activate && basicswap-run --datadir=$COINDATA_PATH"
echo "!!!DO NOT FORGET TO WRITE DOWN THE 24 WORDS (RECOVERY PHRASE) PRINTED A FEW LINES ABOVE!!!"
echo "If you have added XMR support, please write down the CURRENT_XMR_HEIGHT=$CURRENT_XMR_HEIGHT"
echo "You will need this number if you want to restore the XMR node from the seed phrase"
