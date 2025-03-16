#!/bin/bash

# macOS Development Environment Setup Script
# For Azure backend services with Node.js, React, React Native, Docker, Kubernetes
# ------------------------------------------------------------------------------

# Exit on error, but continue if a specific command fails
set -e

echo "========================================================"
echo "🚀 Starting macOS development environment setup"
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
if ! grep -q "plugins=(git node npm docker docker-compose kubectl aws azure vscode)" ~/.zshrc; then
  echo "Updating zsh plugins..."
  sed -i '' 's/plugins=(git)/plugins=(git node npm docker docker-compose kubectl aws azure vscode)/' ~/.zshrc
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
# Install Essential Developer Tools
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
# Node.js and JavaScript Development Setup
# ------------------------------------------------------------------------------
echo "⚡ Setting up Node.js environment..."

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

# Install essential global npm packages
echo "Installing global npm packages..."
npm_packages=("npm@latest" "yarn" "typescript" "azure-functions-core-tools@4" "create-react-app" "react-native-cli" "expo-cli" "nodemon" "prettier" "eslint")

for package in "${npm_packages[@]}"; do
  echo "Installing $package..."
  npm install -g "$package" || echo "Failed to install $package, continuing..."
done

# ------------------------------------------------------------------------------
# Docker and Kubernetes Setup
# ------------------------------------------------------------------------------
echo "🐳 Setting up Docker and Kubernetes..."

# Docker Desktop - only install if not already present
if [ ! -d "/Applications/Docker.app" ]; then
  echo "Installing Docker Desktop..."
  brew install --cask docker
else
  echo "Docker Desktop already installed, skipping."
fi

# Kubernetes tools - only install if not already present
k8s_tools=("kubectl" "kubectx" "k9s" "helm" "minikube")

for tool in "${k8s_tools[@]}"; do
  if ! brew list "$tool" &>/dev/null; then
    echo "Installing $tool..."
    brew install "$tool"
  else
    echo "$tool already installed, skipping."
  fi
done

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

# Install Azure Storage Explorer if not already installed
if [ ! -d "/Applications/Microsoft Azure Storage Explorer.app" ]; then
  echo "Installing Azure Storage Explorer..."
  brew install --cask microsoft-azure-storage-explorer || echo "Failed to install Azure Storage Explorer, continuing..."
else
  echo "Azure Storage Explorer already installed, skipping."
fi

# ------------------------------------------------------------------------------
# IDE and Code Editors
# ------------------------------------------------------------------------------
echo "💻 Installing VSCode and related software..."

# Install Visual Studio Code if not already installed
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
  echo "Installing Visual Studio Code..."
  brew install --cask visual-studio-code
else
  echo "Visual Studio Code already installed, skipping."
fi

# Install VSCode extensions if VS Code is installed
if command -v code &>/dev/null; then
  echo "Installing VSCode extensions..."
  vscode_extensions=(
    "ms-azuretools.vscode-azurefunctions"
    "ms-azuretools.vscode-docker"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "ms-vscode.azure-account"
    "ms-azuretools.vscode-azureterraform"
    "ms-vscode.vscode-node-azure-pack"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "dsznajder.es7-react-js-snippets"
    "ms-vscode.vscode-typescript-next"
    "redhat.vscode-yaml"
    "msjsdiag.vscode-react-native"
    "mhutchie.git-graph"
    "eamodio.gitlens"
    "GitHub.copilot"
  )

  for extension in "${vscode_extensions[@]}"; do
    code --install-extension "$extension" --force || echo "Failed to install $extension, continuing..."
  done
fi

# ------------------------------------------------------------------------------
# Mobile Development Tools
# ------------------------------------------------------------------------------
echo "📱 Installing mobile development tools..."

# Install Android Studio if not already installed
if [ ! -d "/Applications/Android Studio.app" ]; then
  echo "Installing Android Studio..."
  brew install --cask android-studio
else
  echo "Android Studio already installed, skipping."
fi

# Prompt for Xcode installation if not already installed
if [ ! -d "/Applications/Xcode.app" ]; then
  echo "Please install Xcode from the Mac App Store..."
  open macappstore://itunes.apple.com/app/id497799835
fi

# Install cocoapods for iOS development if not already installed
if ! brew list cocoapods &>/dev/null; then
  echo "Installing cocoapods..."
  brew install cocoapods
else
  echo "cocoapods already installed, skipping."
fi

# Set up Android environment variables in .zshrc if not already there
if ! grep -q "ANDROID_HOME" ~/.zshrc; then
  echo "Setting up Android environment variables..."
  echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
  echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.zshrc
  echo 'export PATH=$PATH:$ANDROID_HOME/tools' >> ~/.zshrc
  echo 'export PATH=$PATH:$ANDROID_HOME/tools/bin' >> ~/.zshrc
  echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.zshrc
fi

# ------------------------------------------------------------------------------
# Additional Development Tools
# ------------------------------------------------------------------------------
echo "🔨 Installing additional development tools..."

# Install database tools if not already installed
db_tools=("mongodb-compass" "pgadmin4" "azure-data-studio")

for tool in "${db_tools[@]}"; do
  if ! brew list --cask "$tool" &>/dev/null 2>&1; then
    echo "Installing $tool..."
    brew install --cask "$tool" || echo "Failed to install $tool, continuing..."
  else
    echo "$tool already installed, skipping."
  fi
done

# Install Postman if not already installed
if [ ! -d "/Applications/Postman.app" ]; then
  echo "Installing Postman..."
  brew install --cask postman
else
  echo "Postman already installed, skipping."
fi

# Install additional tools if not already installed
additional_tools=("redis" "ngrok" "awscli")

for tool in "${additional_tools[@]}"; do
  if ! brew list "$tool" &>/dev/null; then
    echo "Installing $tool..."
    brew install "$tool"
  else
    echo "$tool already installed, skipping."
  fi
done

# ------------------------------------------------------------------------------
# Cleanup and Finalization
# ------------------------------------------------------------------------------
echo "🧹 Cleaning up..."
brew cleanup

# ------------------------------------------------------------------------------
# GitHub SSH Setup
# ------------------------------------------------------------------------------
echo "🔑 Setting up GitHub SSH key..."
if [ ! -f ~/.ssh/id_ed25519 ]; then
  # Generate SSH key
  ssh-keygen -t ed25519 -C "$(git config --get user.email || echo "your_email@example.com")" -f ~/.ssh/id_ed25519 -N ""
  
  # Start ssh-agent and add the key
  eval "$(ssh-agent -s)"
  
  # Create SSH config if it doesn't exist
  if [ ! -f ~/.ssh/config ]; then
    echo "Host *\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/id_ed25519" > ~/.ssh/config
  fi
  
  # Add key to SSH agent
  ssh-add -K ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_ed25519
  
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
echo "✅ macOS development environment setup complete!"
echo "Please restart your terminal to apply all changes."
echo "========================================================"