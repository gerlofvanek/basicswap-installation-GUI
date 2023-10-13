![BasicswapDEX Preview](.github-readme/basicswap_header.jpg)

# BasicSwap (BSX) Installer (WIN 10/11)

Introducing BasicSwap (BSX) - A User-Friendly Installer for WIN 10/11. (Linux, OSX, coming soon)

Are you looking for a hassle-free way to install [BasicSwap](https://basicswapdex.com) (BSX) without having to use the command-line interface (CLI)? We've got you covered! With our user-friendly installer, you can easily set up BasicSwap on your computer, even if you're not a CLI enthusiast/non-technical. 

Please ensure that you execute the .exe file with administrative privileges.

# WIP Todo:
1. Comprehensive Testing across Multiple Platforms
2. Make version for OSX/Linux. 

# 🛠 Installation Guide for Node.js, npm, Yarn, and basicswap-installer Build

This README provides step-by-step instructions on how to install Node.js, npm, Yarn, and build the Windows release for the `basicswap-installer`.

## 📋 Table of Contents

- [Installing Node.js and npm](#installing-nodejs-and-npm)
- [Installing Yarn](#installing-yarn)
- [Building the basicswap-installer for Windows](#building-the-basicswap-installer-for-windows)

## 🚀 Installing Node.js and npm

1. **Visit the Node.js Downloads Page**:
   - Navigate to [Node.js Downloads](https://nodejs.org/en/download/).

2. **Select the Appropriate Version**:
   - Opt for the **LTS (Long Term Support)** version for stability. If you want the latest features, choose the Current version.
   - Download the installer suitable for your OS (Windows or Linux).

3. **Run the Installer**:
   - Launch the installer you downloaded.
   - Follow the on-screen instructions. Ensure npm is selected during the installation process.
   - Finish the installation.

4. **Verify the Installation**:
   - Open a terminal or command prompt.
   - Verify Node.js with: 
     ```bash
     node -v
     ```
   - Verify npm with:
     ```bash
     npm -v
     ```

## 📦 Installing Yarn

1. **Using npm**:
   - Now that npm is installed (it comes bundled with Node.js), use it to globally install Yarn:
     ```bash
     npm install -g yarn
     ```

2. **For Windows Users**:
   - If you're using **Chocolatey**, install Yarn with:
     ```bash
     choco install yarn
     ```

4. **Verify Yarn Installation**:
   - In your terminal or command prompt, verify Yarn using:
     ```bash
     yarn --version
     ```

## 🖥 Building the basicswap-installer for Windows

1. **Navigate to the Project Directory**:
   - `cd path_to_your_project_directory`

2. **Install Dependencies**:
   - Execute the following command to install required dependencies:
     ```bash
     yarn install
     ```

3. **Build the Windows Release**:
   - Use the provided script in `package.json` to build the Windows version:
     ```bash
     yarn run package-win
     ```
   - The packaged application will be available in the `release-builds` directory with builds for both the 32-bit (ia32) and 64-bit (x64) architectures.
