#!/bin/bash

# macOS Development Environment Setup Script (Non-admin version)
# For Azure Microservices with Node.js, React, PostgreSQL, Docker, and Kubernetes
# ------------------------------------------------------------------------------

# Exit on error, but continue if a specific command fails
set -e

echo "========================================================"
echo "🚀 Starting macOS development environment setup for Azure Microservices (non-admin)"
echo "========================================================"

# Check if macOS version is compatible
echo "Checking macOS version..."
os_version=$(sw_vers -productVersion)
echo "macOS version: $os_version"

# Create directories for local tools
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.local/share"

# Add local bin to PATH if not already there
if ! grep -q "$HOME/bin" ~/.zshrc; then
  echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
fi

# ------------------------------------------------------------------------------
# Homebrew Check (cannot install without admin but can use if already installed)
# ------------------------------------------------------------------------------
echo "📦 Checking for Homebrew..."
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew is already installed. We'll use it to install tools."
else
  echo "⚠️ Homebrew is not installed and requires admin privileges to install."
  echo "Please use Jamf Self Service to install developer tools, including:"
  echo "- Visual Studio Code"
  echo "- Docker Desktop"
  echo "- Postman"
  echo "- pgAdmin 4"
  echo "- Azure Data Studio"
  echo ""
  echo "The script will continue with non-admin compatible setup steps."
fi

# ------------------------------------------------------------------------------
# Set up zsh customization (without plugins that require admin)
# ------------------------------------------------------------------------------
echo "🐚 Setting up ZSH customization..."

# Set up Oh My Zsh if not already installed (doesn't require admin)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh is already installed."
fi

# Add useful aliases to .zshrc
if ! grep -q "# Azure Microservices Development Aliases" ~/.zshrc; then
  echo "" >> ~/.zshrc
  echo "# Azure Microservices Development Aliases" >> ~/.zshrc
  echo "alias ll='ls -lah'" >> ~/.zshrc
  echo "alias gs='git status'" >> ~/.zshrc
  echo "alias gl='git log --oneline --graph --decorate --all'" >> ~/.zshrc
  echo "alias k='kubectl'" >> ~/.zshrc
  echo "alias dc='docker-compose'" >> ~/.zshrc
  echo "alias az-login='az login'" >> ~/.zshrc
  
  # Add PATH for Postgres if we detect it's installed through Jamf
  echo 'if [ -d "/Applications/Postgres.app" ]; then' >> ~/.zshrc
  echo '  export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' >> ~/.zshrc
  echo 'fi' >> ~/.zshrc
fi

# ------------------------------------------------------------------------------
# Node.js setup using NVM (doesn't require admin)
# ------------------------------------------------------------------------------
echo "⚡ Setting up Node.js environment using NVM..."

# Install NVM (Node Version Manager)
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

# Install latest stable Node.js if not already installed (doesn't require admin)
echo "Installing latest LTS Node.js version..."
nvm install --lts || echo "Failed to install Node.js, continuing..."
nvm use --lts || echo "Failed to use LTS Node.js version, continuing..."
nvm alias default 'lts/*' || echo "Failed to set default Node.js version, continuing..."

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
  "react-devtools"
)

for package in "${npm_packages[@]}"; do
  echo "Installing $package..."
  npm install -g "$package" || echo "Failed to install $package, continuing..."
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
  echo "- pgAdmin 4"
  echo "- Azure Data Studio"
  
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
  echo "- pgAdmin 4"
  echo "- Azure Data Studio"
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
6. Docker
7. Kubernetes
8. ESLint
9. Prettier
10. REST Client
11. ES7+ React/Redux/React-Native snippets
12. PostgreSQL

You can install these extensions using the command palette (Cmd+Shift+P) and typing "Extensions: Install Extensions".

## Configuring Docker Desktop for Kubernetes

1. Open Docker Desktop
2. Go to Settings/Preferences
3. Navigate to Kubernetes
4. Check "Enable Kubernetes"
5. Click "Apply & Restart"

## Setting Up Azure CLI

Since you don't have admin access, you'll need to install Azure CLI via npm instead of Homebrew:

```bash
npm install -g azure-cli
```

Then authenticate with:

```bash
az login
```

## Working with PostgreSQL

After installing pgAdmin 4 from Jamf Self Service, you can:

1. Open pgAdmin 4
2. Add a new server connection
3. Enter your PostgreSQL server details

## Verifying Your Setup

Run the following commands to verify your tools are properly installed:

```bash
node -v              # Should show your Node.js version
npm -v               # Should show your npm version
docker --version     # Should show Docker version (if installed via Jamf)
az --version         # Should show Azure CLI version (if installed via npm)
code --version       # Should show VS Code version (if installed via Jamf)
```
EOL

echo "Created installation guide at ~/Documents/AzureMicroservicesGuide/install_apps_guide.md"


# ------------------------------------------------------------------------------
# GitHub SSH Setup (doesn't require admin)
# ------------------------------------------------------------------------------
echo "🔑 Setting up GitHub SSH key..."
if [ ! -f ~/.ssh/id_ed25519 ]; then
  # Generate SSH key
  ssh-keygen -t ed25519 -C "$(git config --get user.email || echo "your_email@example.com")" -f ~/.ssh/id_ed25519 -N ""
  
  # Start ssh-agent and add the key
  eval "$(ssh-agent -s)"
  
  # Create SSH config if it doesn't exist
  if [ ! -f ~/.ssh/config ]; then
    mkdir -p ~/.ssh
    echo "Host *" > ~/.ssh/config
    echo "  AddKeysToAgent yes" >> ~/.ssh/config
    echo "  UseKeychain yes" >> ~/.ssh/config
    echo "  IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
    chmod 600 ~/.ssh/config
  fi
  
  # Add key to SSH agent
  ssh-add ~/.ssh/id_ed25519 2>/dev/null || echo "Could not add SSH key to agent"
  
  # Output the public key for GitHub setup
  echo "======================================================"
  echo "Your SSH public key (add this to GitHub):"
  cat ~/.ssh/id_ed25519.pub
  echo "======================================================"
  echo "To add this key to your GitHub account, go to:"
  echo "https://github.com/settings/keys"
else
  echo "SSH key already exists, skipping."
fi

# ------------------------------------------------------------------------------
# Create a local Git configuration (doesn't require admin)
# ------------------------------------------------------------------------------
echo "🔧 Setting up Git configuration..."

# Check if git is configured
if [ -z "$(git config --global user.name)" ]; then
  echo "Enter your name for Git configuration:"
  read -r git_name
  git config --global user.name "$git_name"
else
  echo "Git user.name already configured."
fi

if [ -z "$(git config --global user.email)" ]; then
  echo "Enter your email for Git configuration:"
  read -r git_email
  git config --global user.email "$git_email"
else
  echo "Git user.email already configured."
fi

# Set some helpful Git defaults
git config --global core.editor "nano"
git config --global pull.rebase false
git config --global init.defaultBranch main

# ------------------------------------------------------------------------------
echo "✅ Non-admin macOS development environment setup for Azure Microservices complete!"
echo ""
echo "Summary of setup:"
echo "- Oh My Zsh shell configuration"
echo "- Node.js environment via NVM"
echo "- Essential npm packages for Node.js and React development"
echo "- Git configuration and SSH keys"
echo "- Project workspace at ~/projects/azure-microservices"
echo ""
echo "Applications to install via Jamf Self Service:"
echo "- Visual Studio Code"
echo "- Docker Desktop"
echo "- Postman"
echo "- pgAdmin 4"
echo "- Azure Data Studio"
echo ""
echo "See ~/Documents/AzureMicroservicesGuide/install_apps_guide.md for more details."
echo ""
echo "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
echo "========================================================