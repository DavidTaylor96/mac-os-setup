#!/bin/bash

# macOS Development Environment Setup Script
# For Jamf Self Service integration
# ------------------------------------------------------------------------------

# Exit on error, but continue if a specific command fails
set -e

echo "========================================================"
echo "🚀 Starting macOS development environment setup for Jamf Self Service"
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
if ! grep -q "plugins=(git node npm)" ~/.zshrc; then
  echo "Updating zsh plugins..."
  sed -i '' 's/plugins=(git)/plugins=(git node npm macos)/' ~/.zshrc
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

# ------------------------------------------------------------------------------
# Jamf Self Service Setup
# ------------------------------------------------------------------------------
echo "🍏 Setting up Jamf Self Service..."

# Check if Jamf Self Service is already installed
if [ -d "/Applications/Self Service.app" ]; then
  echo "Jamf Self Service is already installed."
else
  echo "⚠️ Jamf Self Service needs to be installed by your organization."
  echo "Please contact your IT administrator for enrollment instructions."
  echo "The enrollment typically requires:"
  echo "1. Installing a Mobile Device Management (MDM) profile"
  echo "2. Authenticating with your organization credentials"
  echo "3. Waiting for Self Service to be pushed to your device"
fi

# Add Jamf binary to path if it exists
if [ -f "/usr/local/bin/jamf" ]; then
  echo "Jamf binary found at /usr/local/bin/jamf"
  
  # Check if jamf is already in path
  if ! grep -q "alias jamf=" ~/.zshrc; then
    echo 'alias jamf="/usr/local/bin/jamf"' >> ~/.zshrc
  fi
else
  echo "Jamf binary not found. It will be installed when your Mac is enrolled in Jamf management."
fi

# ------------------------------------------------------------------------------
# Install tools for working with Jamf
# ------------------------------------------------------------------------------
echo "🛠️ Installing tools for working with Jamf..."

# Install jq for JSON processing if not already installed
if ! brew list jq &>/dev/null; then
  echo "Installing jq for JSON processing..."
  brew install jq
else
  echo "jq already installed, skipping."
fi

# Install plist editor if not already installed
if ! brew list --cask gpg-suite &>/dev/null 2>&1; then
  echo "Installing GPG Suite (includes GPG Keychain for certificate management)..."
  brew install --cask gpg-suite || echo "Failed to install GPG Suite, continuing..."
else
  echo "GPG Suite already installed, skipping."
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
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "redhat.vscode-yaml"
    "mhutchie.git-graph"
    "eamodio.gitlens"
    "pnp.polacode"
    "ms-vscode.makefile-tools"
    "timonwong.shellcheck"
  )

  for extension in "${vscode_extensions[@]}"; do
    code --install-extension "$extension" --force || echo "Failed to install $extension, continuing..."
  done
fi

# ------------------------------------------------------------------------------
# Configuration Scripts for Jamf Integration
# ------------------------------------------------------------------------------
echo "📝 Creating configuration scripts for Jamf integration..."

# Create directory for Jamf scripts if it doesn't exist
mkdir -p ~/Documents/JamfScripts

# Create example script to check Jamf enrollment status
cat > ~/Documents/JamfScripts/check_jamf_status.sh << 'EOL'
#!/bin/bash

# Check if the Mac is enrolled in Jamf
if [ -f "/usr/local/bin/jamf" ]; then
  echo "This Mac appears to be enrolled in Jamf."
  
  # Check if Self Service app exists
  if [ -d "/Applications/Self Service.app" ]; then
    echo "Jamf Self Service is installed."
    
    # Get the version of Self Service
    SELF_SERVICE_VERSION=$(/usr/bin/defaults read "/Applications/Self Service.app/Contents/Info.plist" CFBundleShortVersionString)
    echo "Self Service version: $SELF_SERVICE_VERSION"
  else
    echo "Jamf Self Service is not installed."
  fi
  
  # Check jamf binary version
  JAMF_VERSION=$(/usr/local/bin/jamf -version)
  echo "Jamf binary version: $JAMF_VERSION"
  
  # Check last check-in time
  LAST_CHECKIN=$(/usr/local/bin/jamf checkJSSConnection | grep "Last Check-in time:" | awk -F': ' '{print $2}')
  if [ -n "$LAST_CHECKIN" ]; then
    echo "Last check-in time: $LAST_CHECKIN"
  else
    echo "Could not determine last check-in time."
  fi
else
  echo "This Mac is not enrolled in Jamf."
  echo "Please contact your IT administrator for enrollment instructions."
fi
EOL

# Make script executable
chmod +x ~/Documents/JamfScripts/check_jamf_status.sh

# Create example script for installing Jamf-managed software
cat > ~/Documents/JamfScripts/install_jamf_apps.sh << 'EOL'
#!/bin/bash

# This script demonstrates how to install applications from Jamf Self Service via CLI
# Note: This requires appropriate permissions and that the application is available in Self Service

if [ -f "/usr/local/bin/jamf" ]; then
  echo "Usage: ./install_jamf_apps.sh [policy_id]"
  echo "Example: ./install_jamf_apps.sh 123"
  echo ""
  echo "To find policy IDs, check with your Jamf administrator."
  
  if [ -n "$1" ]; then
    POLICY_ID="$1"
    echo "Attempting to run policy ID: $POLICY_ID"
    /usr/local/bin/jamf policy -id "$POLICY_ID"
  else
    echo "No policy ID provided. Script will exit."
  fi
else
  echo "Jamf binary not found. This Mac is not enrolled in Jamf."
  echo "Please contact your IT administrator for enrollment instructions."
fi
EOL

# Make script executable
chmod +x ~/Documents/JamfScripts/install_jamf_apps.sh

echo "Created example scripts in ~/Documents/JamfScripts/"

# ------------------------------------------------------------------------------
# Additional Development Tools
# ------------------------------------------------------------------------------
echo "🔨 Installing additional development tools..."

# Install Postman if not already installed
if [ ! -d "/Applications/Postman.app" ]; then
  echo "Installing Postman..."
  brew install --cask postman
else
  echo "Postman already installed, skipping."
fi

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
echo "✅ macOS development environment setup for Jamf Self Service complete!"
echo ""
echo "Important notes:"
echo "1. Jamf Self Service must be installed through your organization's enrollment process."
echo "2. Example scripts for Jamf integration are available in ~/Documents/JamfScripts/"
echo "3. Run ~/Documents/JamfScripts/check_jamf_status.sh to verify your Jamf enrollment status."
echo ""
echo "Please restart your terminal to apply all changes."
echo "========================================================"