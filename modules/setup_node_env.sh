#!/bin/bash

# NVM and NPM Installation Script
# This script installs nvm, the latest LTS Node.js, and configures npm

set -e  # Exit on any error

echo "🚀 Starting NVM and NPM setup..."

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

# Install prerequisites
echo "📦 Installing prerequisites..."
if [[ "$OS" == "mac" ]]; then
    # Check if Xcode command line tools are installed
    if ! xcode-select -p &> /dev/null; then
        echo "Installing Xcode command line tools..."
        xcode-select --install
        echo "⚠️  Please complete Xcode command line tools installation and re-run this script"
        exit 1
    fi
elif [[ "$OS" == "linux" ]]; then
    # Install curl and build essentials if not present
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y curl build-essential libssl-dev
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y curl openssl-devel
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y curl openssl-devel
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm curl base-devel openssl
    fi
fi

# Check if NVM is already installed
if [ -d "$HOME/.nvm" ] || [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "⚠️  NVM is already installed. Updating to latest version..."
    # Source existing NVM if available
    [ -s "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh"
else
    echo "📥 Installing NVM..."
fi

# Install or update NVM
NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
echo "📥 Installing NVM version $NVM_VERSION..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | bash

# Set up NVM environment variables
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

echo "✅ NVM installed successfully"

# Add NVM to shell profile
echo "⚙️  Configuring shell profiles..."

# Function to add NVM to a shell config file
add_nvm_to_profile() {
    local profile_file=$1
    local shell_name=$2
    
    if [ -f "$profile_file" ]; then
        if ! grep -q 'export NVM_DIR="$HOME/.nvm"' "$profile_file"; then
            echo "" >> "$profile_file"
            echo "# NVM configuration" >> "$profile_file"
            echo 'export NVM_DIR="$HOME/.nvm"' >> "$profile_file"
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$profile_file"
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> "$profile_file"
            echo "✅ Added NVM to $shell_name profile"
        else
            echo "✅ NVM already configured in $shell_name profile"
        fi
    fi
}

# Add to various shell profiles
add_nvm_to_profile "$HOME/.bashrc" "bash"
add_nvm_to_profile "$HOME/.zshrc" "zsh"
add_nvm_to_profile "$HOME/.profile" "general"

# Reload current shell if it's bash or zsh
if [ -n "$BASH_VERSION" ]; then
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    [ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"
fi

# Verify NVM installation
if ! command -v nvm &> /dev/null; then
    echo "⚠️  NVM command not found. Sourcing NVM manually..."
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
fi

# Install latest LTS Node.js
echo "📥 Installing latest LTS Node.js..."
nvm install --lts
nvm use --lts
nvm alias default lts/*

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)

echo "✅ Node.js $NODE_VERSION installed"
echo "✅ NPM $NPM_VERSION installed"

# Configure NPM
echo "⚙️  Configuring NPM..."

# Check for existing .npmrc conflicts with NVM
if [ -f "$HOME/.npmrc" ]; then
    echo "🔍 Checking for .npmrc conflicts with NVM..."
    if grep -q "^prefix=" "$HOME/.npmrc" || grep -q "^globalconfig=" "$HOME/.npmrc"; then
        echo "⚠️  Found conflicting NPM configuration. Backing up and fixing..."
        cp "$HOME/.npmrc" "$HOME/.npmrc.backup.$(date +%s)"
        # Remove conflicting lines
        sed -i.bak '/^prefix=/d; /^globalconfig=/d' "$HOME/.npmrc" 2>/dev/null || true
        echo "✅ Removed conflicting prefix/globalconfig settings"
        echo "📁 Backup saved to ~/.npmrc.backup.*"
    fi
fi

# Let NVM handle the prefix automatically - don't set a custom prefix
# This prevents conflicts when switching Node versions
echo "✅ NPM will use NVM-managed prefixes for each Node version"

# NPM global packages will be managed by NVM per Node version
# No need to modify PATH since NVM handles this automatically

# Configure npm for better security and performance
npm config set fund false  # Disable funding messages
npm config set audit-level moderate  # Set reasonable audit level
npm config set init-license MIT  # Set default license
npm config set init-author-name "$(git config user.name 2>/dev/null || echo '')"
npm config set init-author-email "$(git config user.email 2>/dev/null || echo '')"

echo "✅ NPM configured successfully"

# Install essential global packages
echo "📦 Installing essential global packages..."

GLOBAL_PACKAGES=(
    "npm@latest"           # Latest npm
    "yarn"                 # Alternative package manager
    "pnpm"                 # Fast, disk space efficient package manager
    "nodemon"              # Auto-restart for development
    "live-server"          # Simple development server
    "http-server"          # Simple HTTP server
    "create-react-app"     # React app generator
    "typescript"           # TypeScript compiler
    "ts-node"              # TypeScript execution for Node.js
    "@vue/cli"             # Vue.js CLI
    "eslint"               # JavaScript linter
    "prettier"             # Code formatter
    "pm2"                  # Production process manager
    "serve"                # Static file server
)

for package in "${GLOBAL_PACKAGES[@]}"; do
    echo "📥 Installing $package..."
    npm install -g "$package" --silent
done

echo "✅ Essential global packages installed"

# Create useful npm scripts template
echo "📝 Creating useful npm aliases and shortcuts..."

# Add useful npm aliases to shell profiles
add_npm_aliases_to_profile() {
    local profile_file=$1
    if [ -f "$profile_file" ]; then
        if ! grep -q "# NPM aliases" "$profile_file"; then
            cat >> "$profile_file" << 'EOF'

# NPM aliases and shortcuts
alias npi='npm install'
alias npd='npm install --save-dev'
alias npu='npm uninstall'
alias nps='npm start'
alias npt='npm test'
alias npb='npm run build'
alias npl='npm run lint'
alias npf='npm run format'
alias npr='npm run'
alias npg='npm list -g --depth=0'
alias npo='npm outdated'
alias npc='npm run clean'
alias npw='npm run watch'
alias npd='npm run dev'

# Node version management
alias nvml='nvm list'
alias nvmu='nvm use'
alias nvmi='nvm install'
alias nvmc='nvm current'
alias nvmr='nvm run'

# Yarn alternatives (if yarn is available)
if command -v yarn &> /dev/null; then
    alias yi='yarn install'
    alias ya='yarn add'
    alias yad='yarn add --dev'
    alias yr='yarn remove'
    alias ys='yarn start'
    alias yt='yarn test'
    alias yb='yarn build'
    alias yu='yarn upgrade'
fi
EOF
        fi
    fi
}

add_npm_aliases_to_profile "$HOME/.bashrc"
add_npm_aliases_to_profile "$HOME/.zshrc"

# Create a sample package.json template
mkdir -p "$HOME/.npm-init"
cat > "$HOME/.npm-init/package.json" << 'EOF'
{
  "name": "",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "echo \"Error: no test specified\" && exit 1",
    "lint": "eslint .",
    "format": "prettier --write .",
    "build": "echo \"Add your build script here\""
  },
  "keywords": [],
  "author": "",
  "license": "MIT"
}
EOF

echo "✅ NPM aliases and templates created"

echo ""
echo "🎉 NVM and NPM setup completed successfully!"
echo ""
echo "✨ What's installed:"
echo "• NVM (Node Version Manager) - $NVM_VERSION"
echo "• Node.js LTS - $NODE_VERSION"
echo "• NPM - $NPM_VERSION"
echo "• Essential global packages:"
echo "  - yarn, pnpm (alternative package managers)"
echo "  - nodemon, live-server, http-server (development tools)"
echo "  - create-react-app, @vue/cli (framework tools)"
echo "  - typescript, ts-node (TypeScript support)"
echo "  - eslint, prettier (code quality tools)"
echo "  - pm2, serve (production tools)"
echo ""
echo "🔧 Configuration:"
echo "• NVM manages Node.js versions and their global packages automatically"
echo "• Each Node version has its own global package directory"
echo "• No manual prefix configuration needed (NVM handles this)"
echo "• Useful aliases added (npi, nps, npt, nvmu, etc.)"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc (or ~/.bashrc)"
echo "2. Verify installation: nvm --version && node --version && npm --version"
echo "3. Try commands:"
echo "   • nvm list (show installed Node versions)"
echo "   • npm list -g --depth=0 (show global packages)"
echo "   • npi <package> (shortcut for npm install)"
echo ""
echo "Useful commands:"
echo "• nvm install node (install latest Node.js)"
echo "• nvm use 18 (switch to Node.js v18)"
echo "• nvm alias default 18 (set default version)"
echo "• npm init -y (quick package.json creation)"
echo ""
echo "Happy Node.js development! 🚀✨"
