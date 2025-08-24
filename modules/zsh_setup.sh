#!/bin/bash

# Oh My Zsh Installation Script
# This script installs zsh, Oh My Zsh, and sets zsh as the default shell

set -e  # Exit on any error

echo "🚀 Starting Oh My Zsh installation..."

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
else
    echo "❌ Unsupported operating system: $OSTYPE"
    exit 1
fi

# Install zsh if not already installed
echo "📦 Checking if zsh is installed..."
if ! command -v zsh &> /dev/null; then
    echo "Installing zsh..."
    if [[ "$OS" == "mac" ]]; then
        # Check if Homebrew is installed
        if command -v brew &> /dev/null; then
            brew install zsh
        else
            echo "❌ Homebrew not found. Please install Homebrew first or install zsh manually."
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        # Detect package manager and install zsh
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y zsh
        elif command -v yum &> /dev/null; then
            sudo yum install -y zsh
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y zsh
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm zsh
        else
            echo "❌ No supported package manager found. Please install zsh manually."
            exit 1
        fi
    fi
else
    echo "✅ zsh is already installed"
fi

# Install Oh My Zsh
echo "📦 Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "⚠️  Oh My Zsh is already installed. Skipping installation."
else
    # Download and install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh installed successfully"
fi

# Install essential plugins
echo "🔌 Installing essential plugins..."

# Install zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    echo "📥 Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    echo "✅ zsh-autosuggestions installed"
else
    echo "✅ zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    echo "📥 Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    echo "✅ zsh-syntax-highlighting installed"
else
    echo "✅ zsh-syntax-highlighting already installed"
fi

# Install zsh-completions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]; then
    echo "📥 Installing zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions
    echo "✅ zsh-completions installed"
else
    echo "✅ zsh-completions already installed"
fi

# Get the path to zsh
ZSH_PATH=$(which zsh)
echo "🔍 zsh path: $ZSH_PATH"

# Add zsh to /etc/shells if not already there
if ! grep -Fxq "$ZSH_PATH" /etc/shells; then
    echo "📝 Adding zsh to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
else
    echo "✅ zsh is already in /etc/shells"
fi

# Change default shell to zsh
echo "🔧 Setting zsh as default shell..."
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    chsh -s "$ZSH_PATH"
    echo "✅ Default shell changed to zsh"
    echo "ℹ️  You may need to log out and log back in for the change to take effect"
else
    echo "✅ zsh is already the default shell"
fi

# Configure .zshrc with essential plugins and cloud theme
echo "⚙️  Configuring .zshrc with essential plugins and cloud theme..."
cat > "$HOME/.zshrc" << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set theme to cloud
ZSH_THEME="cloud"

# Essential plugins for productivity
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    command-not-found
    colored-man-pages
    extract
    web-search
    copypath
    copyfile
    dirhistory
)

# Load zsh-completions
autoload -U compinit && compinit

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

# Enable autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
EOF

echo "✅ .zshrc configured with cloud theme and essential plugins"

echo ""
echo "🎉 Installation completed successfully!"
echo ""
echo "✨ What's installed:"
echo "• Oh My Zsh with cloud theme"
echo "• Essential plugins:"
echo "  - git (Git integration and aliases)"
echo "  - zsh-autosuggestions (Command suggestions based on history)"
echo "  - zsh-syntax-highlighting (Real-time syntax highlighting)"
echo "  - zsh-completions (Enhanced tab completions)"
echo "  - command-not-found (Suggests packages for missing commands)"
echo "  - colored-man-pages (Colorized manual pages)"
echo "  - extract (Smart archive extraction)"
echo "  - web-search (Quick web searches from terminal)"
echo "  - copypath/copyfile (Copy file paths/contents to clipboard)"
echo "  - dirhistory (Navigate directory history with Alt+arrows)"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: exec zsh"
echo "2. Try these features:"
echo "   • Type a command and see syntax highlighting"
echo "   • Start typing and get autosuggestions (press → to accept)"
echo "   • Use 'extract filename' to extract any archive"
echo "   • Use 'google searchterm' to search Google from terminal"
echo ""
echo "Useful aliases added:"
echo "• ll, la, l (enhanced ls commands)"
echo "• .., ... (quick directory navigation)"
echo ""
echo "Happy coding with your supercharged terminal! 🚀✨"
