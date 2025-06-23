#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
FORCE=false
if [[ "$1" == "--force" ]]; then
    FORCE=true
    log_warning "Force mode enabled - existing configurations will be overwritten"
fi

# Function to check if configs are identical
configs_identical() {
    local local_dir="$1"
    local repo_dir="$2"
    
    if [[ ! -d "$local_dir" ]]; then
        return 1  # Local config doesn't exist
    fi
    
    if [[ ! -d "$repo_dir" ]]; then
        return 1  # Repo config doesn't exist
    fi
    
    # Compare directories (ignoring generated files)
    diff -rq "$local_dir" "$repo_dir" >/dev/null 2>&1
    return $?
}

# Show help
show_help() {
    echo "Dotfiles Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help     Show this help message"
    echo "  --force    Force installation (overwrite existing configs)"
    echo ""
    echo "This script will:"
    echo "  - Install Neovim and tmux"
    echo "  - Deploy configurations (only if different or missing)"
    echo "  - Setup tmux plugin manager"
    echo "  - Add vim=nvim alias to shell configs"
    echo ""
    echo "The script is idempotent - it can be run multiple times safely."
    echo "Use --force to reinstall configurations even if they exist."
    echo ""
}

# Handle help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# Install packages function
install_packages() {
    log_info "Checking and installing required packages..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_info "Installing on Linux..."
        if command -v apt >/dev/null 2>&1; then
            sudo apt update
            sudo apt install -y neovim tmux git curl
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y neovim tmux git curl
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm neovim tmux git curl
        else
            log_error "Unsupported Linux distribution"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Installing on macOS..."
        if ! command -v brew >/dev/null 2>&1; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install neovim tmux git
    else
        log_error "Unsupported OS"
        exit 1
    fi
    
    log_success "Package installation completed"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deploy configurations function
deploy_configs() {
    log_info "Checking configuration deployment..."
    
    # Create .config directory
    mkdir -p "$HOME/.config"
    
    # Check nvim config
    if [[ "$FORCE" == true ]] || ! configs_identical "$HOME/.config/nvim" "$SCRIPT_DIR/config/nvim"; then
        if [[ -d "$HOME/.config/nvim" ]]; then
            log_info "Backing up existing nvim config..."
            mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
        fi
        log_info "Installing nvim configuration..."
        cp -r "$SCRIPT_DIR/config/nvim" "$HOME/.config/"
        log_success "nvim configuration deployed"
    else
        log_success "nvim configuration is already up to date"
    fi
    
    # Check tmux config
    if [[ "$FORCE" == true ]] || ! configs_identical "$HOME/.config/tmux" "$SCRIPT_DIR/config/tmux"; then
        if [[ -d "$HOME/.config/tmux" ]]; then
            log_info "Backing up existing tmux config..."
            mv "$HOME/.config/tmux" "$HOME/.config/tmux.backup.$(date +%s)"
        fi
        log_info "Installing tmux configuration..."
        cp -r "$SCRIPT_DIR/config/tmux" "$HOME/.config/"
        log_success "tmux configuration deployed"
    else
        log_success "tmux configuration is already up to date"
    fi
}

# Install TPM function
install_tpm() {
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        log_info "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        log_success "TPM installed"
    else
        log_success "TPM is already installed"
    fi
}

# Setup shell aliases function
setup_shell_aliases() {
    log_info "Setting up vim->nvim alias..."
    
    local alias_added=false
    
    # Add to .zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "alias vim=nvim" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Use nvim as default vim" >> "$HOME/.zshrc"
            echo "alias vim=nvim" >> "$HOME/.zshrc"
            log_success "Added vim=nvim alias to .zshrc"
            alias_added=true
        else
            log_success "vim=nvim alias already exists in .zshrc"
        fi
    fi
    
    # Add to .bashrc if it exists
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "alias vim=nvim" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Use nvim as default vim" >> "$HOME/.bashrc"
            echo "alias vim=nvim" >> "$HOME/.bashrc"
            log_success "Added vim=nvim alias to .bashrc"
            alias_added=true
        else
            log_success "vim=nvim alias already exists in .bashrc"
        fi
    fi
    
    # Add to .bash_profile if it exists (macOS default)
    if [[ -f "$HOME/.bash_profile" ]]; then
        if ! grep -q "alias vim=nvim" "$HOME/.bash_profile"; then
            echo "" >> "$HOME/.bash_profile"
            echo "# Use nvim as default vim" >> "$HOME/.bash_profile"
            echo "alias vim=nvim" >> "$HOME/.bash_profile"
            log_success "Added vim=nvim alias to .bash_profile"
            alias_added=true
        else
            log_success "vim=nvim alias already exists in .bash_profile"
        fi
    fi
    
    if [[ "$alias_added" == false ]]; then
        log_success "All vim=nvim aliases are already configured"
    fi
}

# Main installation function
main() {
    log_info "Starting dotfiles setup..."
    
    install_packages
    deploy_configs
    install_tpm
    setup_shell_aliases
    
    echo ""
    log_success "Installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Start tmux and press Ctrl+Space + I to install plugins"
    echo "  2. Open nvim to complete NvChad setup"
    echo "  3. Restart your terminal or run 'source ~/.zshrc' to use 'vim' alias"
    echo ""
    log_info "The setup script can be run multiple times safely."
}

# Run main function
main