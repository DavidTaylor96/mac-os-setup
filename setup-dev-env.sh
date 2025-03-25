#!/bin/bash

# macOS Development Environment Setup Script for Jamf Self Service
# Non-sudo version (for users without administrator privileges)
# ------------------------------------------------------------------------------

# Exit on error, but continue if a specific command fails
set -e

echo "========================================================"
echo "🚀 Starting macOS development environment setup for Jamf Self Service (non-sudo)"
echo "========================================================"

# Check if macOS version is compatible
echo "Checking macOS version..."
os_version=$(sw_vers -productVersion)
echo "macOS version: $os_version"

# Create a local bin directory if it doesn't exist
mkdir -p "$HOME/bin"
# Add to PATH if not already there
if ! grep -q "HOME/bin" ~/.zshrc; then
  echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
fi

# ------------------------------------------------------------------------------
# Homebrew installation check (non-sudo option)
# ------------------------------------------------------------------------------
echo "📦 Checking for Homebrew..."
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew already installed. Updating..."
  brew update
else
  echo "⚠️ Homebrew installation typically requires sudo access."
  echo "You can try the unattended installation which might work in some environments:"
  echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo ""
  echo "Alternatively, you can install packages manually or use other methods."
  echo "Continuing with the rest of the setup..."
fi

# ------------------------------------------------------------------------------
# Set up zsh customization (without plugins that require brew)
# ------------------------------------------------------------------------------
echo "🐚 Setting up ZSH customization..."

# Set up Oh My Zsh if not already installed (doesn't require sudo)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh is already installed."
fi

# Add useful aliases to .zshrc if not already there
if ! grep -q "# User aliases for development" ~/.zshrc; then
  echo "" >> ~/.zshrc
  echo "# User aliases for development" >> ~/.zshrc
  echo "alias ll='ls -lah'" >> ~/.zshrc
  echo "alias la='ls -lAh'" >> ~/.zshrc
  echo "alias l='ls -lh'" >> ~/.zshrc
  echo "alias gs='git status'" >> ~/.zshrc
  echo "alias gl='git log --oneline --graph --decorate --all'" >> ~/.zshrc
fi

# ------------------------------------------------------------------------------
# Node.js setup using NVM (doesn't require sudo)
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

# Install latest stable Node.js if not already installed (doesn't require sudo)
echo "Installing latest LTS Node.js version..."
nvm install --lts || echo "Failed to install Node.js, continuing..."
nvm use --lts || echo "Failed to use LTS Node.js version, continuing..."
nvm alias default 'lts/*' || echo "Failed to set default Node.js version, continuing..."

# ------------------------------------------------------------------------------
# Jamf Self Service Setup (reading only, no installation)
# ------------------------------------------------------------------------------
echo "🍏 Checking Jamf Self Service status..."

# Check if Jamf Self Service is already installed
if [ -d "/Applications/Self Service.app" ]; then
  echo "Jamf Self Service is already installed."
  
  # Get the version of Self Service without sudo
  if [ -f "/Applications/Self Service.app/Contents/Info.plist" ]; then
    SELF_SERVICE_VERSION=$(/usr/bin/defaults read "/Applications/Self Service.app/Contents/Info.plist" CFBundleShortVersionString)
    echo "Self Service version: $SELF_SERVICE_VERSION"
  fi
else
  echo "⚠️ Jamf Self Service is not installed."
  echo "Please contact your IT administrator for enrollment instructions."
  echo "The enrollment typically requires:"
  echo "1. Installing a Mobile Device Management (MDM) profile"
  echo "2. Authenticating with your organization credentials"
  echo "3. Waiting for Self Service to be pushed to your device"
fi

# Add Jamf binary to path if it exists (doesn't require sudo)
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
# Configuration Scripts for Jamf Integration (doesn't require sudo)
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
  
  # Check last check-in time if possible without sudo
  LAST_CHECKIN=$(/usr/local/bin/jamf checkJSSConnection 2>/dev/null | grep "Last Check-in time:" | awk -F': ' '{print $2}')
  if [ -n "$LAST_CHECKIN" ]; then
    echo "Last check-in time: $LAST_CHECKIN"
  else
    echo "Could not determine last check-in time (may require higher privileges)."
  fi
else
  echo "This Mac is not enrolled in Jamf."
  echo "Please contact your IT administrator for enrollment instructions."
fi
EOL

# Make script executable
chmod +x ~/Documents/JamfScripts/check_jamf_status.sh

# Create example script for listing available Jamf Self Service items
cat > ~/Documents/JamfScripts/list_self_service_items.sh << 'EOL'
#!/bin/bash

# This script attempts to list available Self Service items without sudo

if [ -d "/Applications/Self Service.app" ]; then
  echo "Jamf Self Service is installed."
  echo ""
  echo "To view available Self Service items:"
  echo "1. Open Self Service from your Applications folder"
  echo "2. Log in with your organization credentials if prompted"
  echo "3. Browse the catalog of available software"
  echo ""
  echo "Launching Self Service application..."
  open "/Applications/Self Service.app"
else
  echo "Jamf Self Service is not installed on this system."
  echo "Please contact your IT administrator for assistance."
fi
EOL

# Make script executable
chmod +x ~/Documents/JamfScripts/list_self_service_items.sh

echo "Created example scripts in ~/Documents/JamfScripts/"

# ------------------------------------------------------------------------------
# GitHub SSH Setup (doesn't require sudo)
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
# Create a local Git configuration (doesn't require sudo)
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
echo "✅ Non-sudo macOS development environment setup for Jamf Self Service complete!"
echo ""
echo "Important notes:"
echo "1. Some tools could not be installed without sudo access"
echo "2. Jamf Self Service must be installed through your organization's enrollment process"
echo "3. Example scripts for Jamf integration are available in ~/Documents/JamfScripts/"
echo "4. Run ~/Documents/JamfScripts/check_jamf_status.sh to verify your Jamf enrollment status"
echo ""
echo "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
echo "========================================================"