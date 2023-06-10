# BasicSwap Installation Script

This script automates the installation and setup process for BasicSwap. The main steps performed by the script are as follows:

1. **Install prerequisites**: The script detects the Linux distribution being used and installs the necessary dependencies for BasicSwap. In case of MacOS or Windows, it does some preliminary verifications to make sure you have brew or chocolatey installed.

2. **Prompt for installation path**: The user is asked to provide the absolute path where BasicSwap will be installed.

3. **Select coins to include**: The user is prompted to select which cryptocurrencies they want to include in BasicSwap. They can choose from Monero, Bitcoin, Litecoin, Dash, PIVX, and Firo.

4. **Set up coin data directory**: A new directory is created to store data for the cryptocurrencies supported by BasicSwap.

5. **Check for existing data directory**: If the coin data directory already exists, the user is prompted to decide whether they want to perform a fresh installation and remove the existing directory.

6. **Create a Python virtual environment**: A new Python virtual environment is created to isolate the BasicSwap installation from the system's Python environment.

7. **Install the Coincurve library**: The Coincurve library is fetched and installed, as it's a required dependency for BasicSwap.

8. **Clone and install BasicSwap**: The BasicSwap repository is cloned, and the necessary Python packages are installed.

9. **Initialize the coins data directory**: The script initializes the coin data directory with the selected cryptocurrencies and sets up the fast-sync for Bitcoin, if chosen.

10. **Print instructions**: The script outputs instructions for starting BasicSwap, including the command to activate the virtual environment and start the BasicSwap application. It also reminds the user to write down the recovery phrase and the current Monero block height, if Monero support was added.

To use this script, simply run it on your system and follow the prompts. Make sure to have the necessary privileges to install packages and create directories as needed.
