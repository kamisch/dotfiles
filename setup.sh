#!/bin/bash

set -e

# Detect OS and install packages
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Installing on Linux..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y neovim tmux git curl
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y neovim tmux git curl
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm neovim tmux git curl
    else
        echo "Unsupported Linux distribution"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing on macOS..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install neovim tmux git
else
    echo "Unsupported OS"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup existing configs
if [[ -d "$HOME/.config/nvim" ]]; then
    echo "Backing up existing nvim config..."
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
fi

if [[ -d "$HOME/.config/tmux" ]]; then
    echo "Backing up existing tmux config..."
    mv "$HOME/.config/tmux" "$HOME/.config/tmux.backup.$(date +%s)"
fi

# Create .config directory
mkdir -p "$HOME/.config"

# Copy configurations
echo "Installing configurations..."
cp -r "$SCRIPT_DIR/config/nvim" "$HOME/.config/"
cp -r "$SCRIPT_DIR/config/tmux" "$HOME/.config/"

# Install TPM (tmux plugin manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Installation complete!"
echo "Start tmux and press prefix + I to install plugins"
echo "Open nvim to complete NvChad setup"