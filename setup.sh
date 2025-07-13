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
    echo "  - Install Neovim and tmux (Linux/macOS) or Neovim and Git (Windows)"
    echo "  - Deploy configurations (only if different or missing)"
    echo "  - Setup tmux plugin manager (if tmux is available)"
    echo "  - Add vim=nvim alias to shell configs (bash/zsh/PowerShell)"
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
    
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux-musl"* ]] || [[ -f /etc/alpine-release ]]; then
        log_info "Installing on Linux..."
        if command -v apk >/dev/null 2>&1; then
            sudo apk update
            sudo apk add neovim tmux git curl
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update
            # Install newer Neovim from snap or AppImage for better compatibility
            if command -v snap >/dev/null 2>&1; then
                sudo snap install nvim --classic
            else
                # Fall back to apt version (may be older)
                sudo apt install -y neovim
            fi
            sudo apt install -y tmux git curl
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
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        log_info "Installing on Windows..."
        
        # Check if winget is available (Windows 10 1709+ / Windows 11)
        if command -v winget >/dev/null 2>&1; then
            log_info "Using winget for package installation..."
            # Install packages with winget
            winget install --id=Neovim.Neovim --exact --source=winget --accept-package-agreements --accept-source-agreements
            winget install --id=Git.Git --exact --source=winget --accept-package-agreements --accept-source-agreements
            
            # Check if we're in WSL or have access to Unix tools
            if command -v wsl >/dev/null 2>&1 || command -v bash >/dev/null 2>&1; then
                # Try to install tmux via WSL or available package manager
                if command -v wsl >/dev/null 2>&1; then
                    log_info "Installing tmux via WSL..."
                    wsl -- sudo apt update && wsl -- sudo apt install -y tmux
                else
                    log_warning "tmux not available on Windows. Consider using WSL or Windows Terminal for terminal multiplexing."
                fi
            else
                log_warning "tmux not available on Windows. Consider using WSL or Windows Terminal for terminal multiplexing."
            fi
            
        # Fall back to chocolatey if winget is not available
        elif command -v choco >/dev/null 2>&1; then
            log_info "Using Chocolatey for package installation..."
            choco install neovim git -y
            log_warning "tmux not available via Chocolatey. Consider using WSL or Windows Terminal."
        else
            log_error "Neither winget nor chocolatey found. Please install one of them first:"
            log_error "  - winget: Available on Windows 10 1709+ and Windows 11"
            log_error "  - chocolatey: https://chocolatey.org/install"
            exit 1
        fi
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
    
    # Determine config paths based on OS
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        # Windows paths
        NVIM_CONFIG_DIR="$HOME/AppData/Local/nvim"
        TMUX_CONFIG_DIR="$HOME/.config/tmux"  # tmux still uses Unix-style path even on Windows
        CONFIG_BASE_DIR="$HOME/AppData/Local"
        
        # Create necessary directories
        mkdir -p "$CONFIG_BASE_DIR"
        mkdir -p "$HOME/.config"
    else
        # Unix-like systems (Linux, macOS)
        NVIM_CONFIG_DIR="$HOME/.config/nvim"
        TMUX_CONFIG_DIR="$HOME/.config/tmux"
        CONFIG_BASE_DIR="$HOME/.config"
        
        # Create .config directory
        mkdir -p "$CONFIG_BASE_DIR"
    fi
    
    # Check nvim config
    if [[ "$FORCE" == true ]] || ! configs_identical "$NVIM_CONFIG_DIR" "$SCRIPT_DIR/config/nvim"; then
        if [[ -d "$NVIM_CONFIG_DIR" ]]; then
            log_info "Backing up existing nvim config..."
            mv "$NVIM_CONFIG_DIR" "$NVIM_CONFIG_DIR.backup.$(date +%s)"
        fi
        log_info "Installing nvim configuration..."
        cp -r "$SCRIPT_DIR/config/nvim" "$NVIM_CONFIG_DIR"
        log_success "nvim configuration deployed to $NVIM_CONFIG_DIR"
    else
        log_success "nvim configuration is already up to date"
    fi
    
    # Check tmux config (skip on Windows if tmux not available)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        if command -v tmux >/dev/null 2>&1 || command -v wsl >/dev/null 2>&1; then
            deploy_tmux_config
        else
            log_info "Skipping tmux configuration (tmux not available on Windows)"
        fi
    else
        deploy_tmux_config
    fi
}

# Helper function to deploy tmux config
deploy_tmux_config() {
    if [[ "$FORCE" == true ]] || ! configs_identical "$TMUX_CONFIG_DIR" "$SCRIPT_DIR/config/tmux"; then
        if [[ -d "$TMUX_CONFIG_DIR" ]]; then
            log_info "Backing up existing tmux config..."
            mv "$TMUX_CONFIG_DIR" "$TMUX_CONFIG_DIR.backup.$(date +%s)"
        fi
        log_info "Installing tmux configuration..."
        cp -r "$SCRIPT_DIR/config/tmux" "$TMUX_CONFIG_DIR"
        log_success "tmux configuration deployed to $TMUX_CONFIG_DIR"
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
    
    # Windows-specific alias setup
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        # PowerShell profile setup
        local ps_profile_paths=(
            "$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
            "$HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
        )
        
        for ps_profile in "${ps_profile_paths[@]}"; do
            local ps_profile_dir=$(dirname "$ps_profile")
            if [[ ! -d "$ps_profile_dir" ]]; then
                log_info "Creating PowerShell profile directory: $ps_profile_dir"
                mkdir -p "$ps_profile_dir"
            fi
            
            if [[ ! -f "$ps_profile" ]] || ! grep -q "Set-Alias.*vim.*nvim" "$ps_profile" 2>/dev/null; then
                log_info "Adding vim=nvim alias to PowerShell profile: $ps_profile"
                echo "" >> "$ps_profile"
                echo "# Use nvim as default vim" >> "$ps_profile"
                echo "Set-Alias -Name vim -Value nvim" >> "$ps_profile"
                log_success "Added vim=nvim alias to PowerShell profile"
                alias_added=true
            else
                log_success "vim=nvim alias already exists in PowerShell profile"
            fi
        done
        
        # Git Bash / MSYS2 / Cygwin alias setup (if in those environments)
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
        
        # Create a batch file for Command Prompt users
        local cmd_alias_file="$HOME/nvim-alias.bat"
        if [[ ! -f "$cmd_alias_file" ]]; then
            log_info "Creating Command Prompt alias script..."
            cat > "$cmd_alias_file" << 'EOF'
@echo off
REM Batch file to use nvim as vim
REM Add this file's directory to your PATH or run it directly
nvim %*
EOF
            log_success "Created Command Prompt alias script at $cmd_alias_file"
            log_info "To use vim=nvim in Command Prompt, either:"
            log_info "  1. Add $(dirname "$cmd_alias_file") to your PATH"
            log_info "  2. Or copy nvim-alias.bat to a directory already in PATH and rename to vim.bat"
            alias_added=true
        fi
        
    else
        # Unix-like systems (Linux, macOS) - existing logic
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
    
    # OS-specific next steps
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        echo "  1. Open nvim to complete NvChad setup"
        if command -v tmux >/dev/null 2>&1 || command -v wsl >/dev/null 2>&1; then
            echo "  2. Start tmux and press Ctrl+Space + I to install plugins"
        else
            echo "  2. Consider using Windows Terminal or WSL for better terminal experience"
        fi
        echo "  3. Restart PowerShell/terminal to use 'vim' alias"
        echo "  4. For Command Prompt users: copy nvim-alias.bat to PATH or rename to vim.bat"
    else
        echo "  1. Start tmux and press Ctrl+Space + I to install plugins"
        echo "  2. Open nvim to complete NvChad setup"
        echo "  3. Restart your terminal or run 'source ~/.zshrc' to use 'vim' alias"
    fi
    
    echo ""
    log_info "The setup script can be run multiple times safely."
}

# Run main function
main