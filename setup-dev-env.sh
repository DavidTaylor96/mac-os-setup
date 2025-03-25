#!/bin/bash

# macOS Development Environment Setup Script
# For Azure Microservices with Node.js, React, PostgreSQL, Docker, and Kubernetes
# Using Homebrew for tools and Jamf Self Service for applications
# ------------------------------------------------------------------------------

# Exit on error, but continue if a specific command fails
set -e

echo "========================================================"
echo "🚀 Starting macOS development environment setup for Azure Microservices"
echo "========================================================"

# Check if macOS version is compatible
echo "Checking macOS version..."
os_version=$(sw_vers -productVersion)
echo "macOS version: $os_version"

# ------------------------------------------------------------------------------
# Install Homebrew (Package Manager)
# ------------------------------------------------------------------------------
echo "📦 Installing Homebrew..."
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew already installed. Updating..."
  brew update
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH for both Intel and Apple Silicon Macs
  if [[ $(uname -m) == 'arm64' ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ------------------------------------------------------------------------------
# Set up zsh with Oh My Zsh
# ------------------------------------------------------------------------------
echo "🐚 Setting up ZSH..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh is already installed."
fi

# Install useful plugins for zsh (only if not already installed)
echo "Installing zsh plugins..."
brew list zsh-syntax-highlighting &>/dev/null || brew install zsh-syntax-highlighting
brew list zsh-autosuggestions &>/dev/null || brew install zsh-autosuggestions

# Add plugins to .zshrc if they aren't already there
if ! grep -q "plugins=(git node npm docker docker-compose kubectl azure)" ~/.zshrc; then
  echo "Updating zsh plugins..."
  sed -i '' 's/plugins=(git)/plugins=(git node npm docker docker-compose kubectl azure vscode)/' ~/.zshrc
fi

# Add syntax highlighting and autosuggestions if not already there
if ! grep -q "zsh-syntax-highlighting.zsh" ~/.zshrc; then
  echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
fi

if ! grep -q "zsh-autosuggestions.zsh" ~/.zshrc; then
  echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
fi

# Install powerlevel10k theme (a popular zsh theme)
brew list powerlevel10k &>/dev/null || brew install romkatv/powerlevel10k/powerlevel10k

if ! grep -q "powerlevel10k.zsh-theme" ~/.zshrc; then
  echo "source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc
fi

# ------------------------------------------------------------------------------
# Install Essential Developer Tools via Homebrew
# ------------------------------------------------------------------------------
echo "🔧 Installing essential developer tools..."

# Install Xcode Command Line Tools
xcode-select --print-path &>/dev/null || xcode-select --install || true

# Install Git and other essential tools if not already installed
tools=("git" "gh" "wget" "jq" "tree" "htop")

for tool in "${tools[@]}"; do
  if ! brew list "$tool" &>/dev/null; then
    echo "Installing $tool..."
    brew install "$tool"
  else
    echo "$tool already installed, skipping."
  fi
done

# ------------------------------------------------------------------------------
# Node.js and JavaScript Development Setup via NVM
# ------------------------------------------------------------------------------
echo "⚡ Setting up Node.js environment for backend development..."

# Install Node.js using NVM (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

  # Add NVM to .zshrc if not already there
  if ! grep -q "NVM_DIR" ~/.zshrc; then
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
  fi
else
  echo "NVM already installed, skipping."
fi

# Source NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install latest stable Node.js if not already installed
echo "Installing latest LTS Node.js version..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

# Install essential global npm packages for Node.js and React development
echo "Installing global npm packages for Node.js/React development..."
npm_packages=(
  "npm@latest" 
  "yarn" 
  "typescript" 
  "ts-node" 
  "create-react-app" 
  "nodemon" 
  "prettier" 
  "eslint" 
  "express-generator" 
  "azure-functions-core-tools@4" 
  "react-devtools"
)

for package in "${npm_packages[@]}"; do
  echo "Installing $package..."
  npm install -g "$package" || echo "Failed to install $package, continuing..."
done

# ------------------------------------------------------------------------------
# Docker and Kubernetes Setup via Homebrew
# ------------------------------------------------------------------------------
echo "🐳 Setting up Docker and Kubernetes CLI tools..."

# Install Kubernetes tools - only install if not already present
k8s_tools=("kubectl" "kubectx" "k9s" "helm" "stern" "kubeval" "kubernetes-cli")

for tool in "${k8s_tools[@]}"; do
  if ! brew list "$tool" &>/dev/null; then
    echo "Installing $tool..."
    brew install "$tool"
  else
    echo "$tool already installed, skipping."
  fi
done

# ------------------------------------------------------------------------------
# Database Tools (PostgreSQL, SQL)
# ------------------------------------------------------------------------------
echo "🗄️ Installing database tools for PostgreSQL and SQL development..."

# Install PostgreSQL client tools
if ! brew list "postgresql@14" &>/dev/null; then
  echo "Installing PostgreSQL client tools..."
  brew install postgresql@14

  # Add PostgreSQL to PATH
  if ! grep -q "postgresql@14" ~/.zshrc; then
    echo 'export PATH="$(brew --prefix)/opt/postgresql@14/bin:$PATH"' >> ~/.zshrc
  fi
else
  echo "PostgreSQL client tools already installed, skipping."
fi

# Install SQL tools
if ! brew list "sqlcmd" &>/dev/null; then
  echo "Installing SQL command-line tools..."
  brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
  brew install msodbcsql17 mssql-tools
else
  echo "SQL command-line tools already installed, skipping."
fi

# ------------------------------------------------------------------------------
# Azure CLI and Development Tools
# ------------------------------------------------------------------------------
echo "☁️ Setting up Azure development tools..."

# Install Azure CLI if not already installed
if ! brew list azure-cli &>/dev/null; then
  echo "Installing Azure CLI..."
  brew install azure-cli
else
  echo "Azure CLI already installed, skipping."
fi

# Configure Azure CLI extensions if Azure CLI is installed
if command -v az &>/dev/null; then
  echo "Installing Azure CLI extensions..."
  az extension add --name azure-devops 2>/dev/null || echo "azure-devops extension already installed or failed to install."
  az extension add --name aks-preview 2>/dev/null || echo "aks-preview extension already installed or failed to install."
fi

# ------------------------------------------------------------------------------
# React and Front-end Development Tools
# ------------------------------------------------------------------------------
echo "🌐 Setting up React and front-end development tools..."

# Install some useful CLI tools for React/front-end development
frontend_tools=("serve" "lighthouse" "http-server")

for tool in "${frontend_tools[@]}"; do
  echo "Installing $tool..."
  npm install -g "$tool" || echo "Failed to install $tool, continuing..."
done

# ------------------------------------------------------------------------------
# Jamf Self Service Applications Check and Installation Guide
# ------------------------------------------------------------------------------
echo "🍏 Checking Jamf Self Service..."

# Check if Jamf Self Service is installed
if [ -d "/Applications/Self Service.app" ]; then
  echo "Jamf Self Service is installed. You can use it to install the following applications:"
  echo "- Visual Studio Code"
  echo "- Docker Desktop"
  echo "- Postman"
  echo "- MongoDB Compass"
  echo "- Azure Data Studio"
  echo "- pgAdmin 4"
  
  echo ""
  echo "Would you like to open Jamf Self Service now? (y/n)"
  read -r open_jamf
  
  if [[ "$open_jamf" =~ ^[Yy]$ ]]; then
    open "/Applications/Self Service.app"
  fi
else
  echo "⚠️ Jamf Self Service is not installed."
  echo "Please contact your IT administrator to install Jamf Self Service."
  echo "Once installed, you can use it to install the following applications:"
  echo "- Visual Studio Code"
  echo "- Docker Desktop"
  echo "- Postman"
  echo "- MongoDB Compass"
  echo "- Azure Data Studio"
  echo "- pgAdmin 4"
fi

# Create a Jamf application installation guide
mkdir -p ~/Documents/AzureMicroservicesGuide

cat > ~/Documents/AzureMicroservicesGuide/install_apps_guide.md << 'EOL'
# Installing Applications for Azure Microservices Development

This guide explains how to install the required applications using Jamf Self Service.

## Required Applications

The following applications should be installed from Jamf Self Service:

1. **Visual Studio Code** - Code editor with excellent support for JavaScript, TypeScript, Node.js, and React
2. **Docker Desktop** - Container platform for microservices development and testing
3. **Postman** - API testing tool for testing microservices endpoints
4. **pgAdmin 4** - PostgreSQL administration tool
5. **Azure Data Studio** - Data management tool for SQL Server and Azure SQL
6. **MongoDB Compass** - GUI for MongoDB (if using MongoDB in your stack)

## Installation Steps

1. Open **Jamf Self Service** from your Applications folder
2. Log in with your organization credentials if prompted
3. Browse or search for each application listed above
4. Click the "Install" button for each application
5. Wait for the installation to complete

## Setting Up VS Code for Azure Microservices Development

After installing VS Code, install these essential extensions:

1. Azure Account
2. Azure Functions
3. Azure App Service
4. Azure Resources
5. Azure Databases
6. Azure Storage
7. Docker
8. Kubernetes
9. ESLint
10. Prettier
11. REST Client
12. ES7+ React/Redux/React-Native snippets
13. PostgreSQL

You can install these extensions using the command palette (Cmd+Shift+P) and typing "Extensions: Install Extensions".

## Configuring Docker Desktop for Kubernetes

1. Open Docker Desktop
2. Go to Settings/Preferences
3. Navigate to Kubernetes
4. Check "Enable Kubernetes"
5. Click "Apply & Restart"

## Connecting to Azure

After installing the Azure CLI via Homebrew, authenticate with:

```bash
az login
```

## Setting Up PostgreSQL Local Development

After installing the PostgreSQL client tools via Homebrew, you can:

1. Create a local database: `createdb my_microservice_db`
2. Connect to it: `psql my_microservice_db`

## Using Azure Data Studio with Azure SQL

1. Open Azure Data Studio
2. Click "New Connection"
3. Enter your Azure SQL server details
4. Use Azure Active Directory authentication when possible

## Verifying Your Setup

Run the following commands to verify your tools are properly installed:

```bash
node -v              # Should show your Node.js version
npm -v               # Should show your npm version
docker --version     # Should show Docker version
kubectl version      # Should show Kubernetes client version
az --version         # Should show Azure CLI version
psql --version       # Should show PostgreSQL client version
```
EOL

echo "Created installation guide at ~/Documents/AzureMicroservicesGuide/install_apps_guide.md"

# ------------------------------------------------------------------------------
# Additional Developer Tools via Homebrew
# ------------------------------------------------------------------------------
echo "🔨 Installing additional CLI development tools..."

# Install additional tools if not already installed
additional_tools=("redis" "ngrok" "terraform" "azure-cli")

for tool in "${additional_tools[@]}"; do
  if ! brew list "$tool" &>/dev/null; then
    echo "Installing $tool..."
    brew install "$tool"
  else
    echo "$tool already installed, skipping."
  fi
done