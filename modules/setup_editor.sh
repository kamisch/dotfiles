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
    echo "  - Install Neovim and tmux (Linux/macOS)"
    echo "  - Install Nerd Fonts for proper icon display"
    echo "  - Deploy configurations (only if different or missing)"
    echo "  - Setup tmux plugin manager"
    echo "  - Add vim=nvim alias to shell configs (bash/zsh)"
    echo "  - Fix Snap PATH issues if needed"
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

# Function to add PATH to shell profiles
add_path_to_profile() {
    local path_entry=$1
    local profile_file=$2
    local shell_name=$3
    
    if [[ -f "$profile_file" ]]; then
        if ! grep -q "$path_entry" "$profile_file"; then
            echo "" >> "$profile_file"
            echo "# Snap binaries PATH" >> "$profile_file"
            echo "$path_entry" >> "$profile_file"
            log_success "Added snap PATH to $shell_name profile"
            return 0
        else
            log_success "Snap PATH already in $shell_name profile"
            return 1
        fi
    fi
    return 1
}

# Install packages function
install_packages() {
    log_info "Checking and installing required packages..."
    
    local snap_nvim_installed=false
    
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux-musl"* ]] || [[ -f /etc/alpine-release ]]; then
        log_info "Installing on Linux..."
        if command -v apk >/dev/null 2>&1; then
            sudo apk update
            sudo apk add neovim tmux git curl unzip fontconfig
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora / RHEL 8+ / CentOS Stream
            log_info "Detected Fedora/RHEL-based system (dnf)..."
            sudo dnf install -y neovim tmux git curl unzip fontconfig
        elif command -v yum >/dev/null 2>&1; then
            # Older RHEL / CentOS 7
            log_info "Detected legacy RHEL/CentOS system (yum)..."
            sudo yum install -y epel-release || true
            sudo yum install -y neovim tmux git curl unzip fontconfig
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update
            # Install newer Neovim from snap for better compatibility
            if command -v snap >/dev/null 2>&1; then
                if ! snap list | grep -q nvim; then
                    log_info "Installing Neovim via Snap for latest version..."
                    sudo snap install nvim --classic
                    snap_nvim_installed=true
                else
                    log_success "Neovim already installed via Snap"
                fi
            else
                # Fall back to apt version (may be older)
                log_info "Installing Neovim via APT (may be older version)..."
                sudo apt install -y neovim
            fi
            sudo apt install -y tmux git curl unzip fontconfig
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm neovim tmux git curl unzip fontconfig
        else
            log_error "Unsupported Linux distribution"
            exit 1
        fi
        
        # Fix Snap PATH if nvim was installed via snap
        if [[ "$snap_nvim_installed" == true ]] || (command -v snap >/dev/null 2>&1 && snap list | grep -q nvim); then
            log_info "Configuring Snap PATH for Neovim..."
            local snap_path_entry='export PATH="/snap/bin:$PATH"'
            local path_added=false
            
            # Add to .zshrc if it exists
            if add_path_to_profile "$snap_path_entry" "$HOME/.zshrc" "zsh"; then
                path_added=true
            fi
            
            # Add to .bashrc if it exists
            if add_path_to_profile "$snap_path_entry" "$HOME/.bashrc" "bash"; then
                path_added=true
            fi
            
            # Add to .profile as fallback
            if add_path_to_profile "$snap_path_entry" "$HOME/.profile" "profile"; then
                path_added=true
            fi
            
            # Export for current session
            if [[ ":$PATH:" != *":/snap/bin:"* ]]; then
                export PATH="/snap/bin:$PATH"
                log_info "Added /snap/bin to current session PATH"
            fi
            
            if [[ "$path_added" == true ]]; then
                log_success "Snap PATH configuration completed"
                log_info "Restart your terminal or run 'source ~/.zshrc' to use nvim command"
            fi
        fi
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Installing on macOS..."
        if ! command -v brew >/dev/null 2>&1; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install neovim tmux git
    else
        log_error "Unsupported OS - only Linux and macOS are supported"
        exit 1
    fi
    
    log_success "Package installation completed"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deploy configurations function
deploy_configs() {
    log_info "Checking configuration deployment..."
    
    # Unix-like systems (Linux, macOS)
    NVIM_CONFIG_DIR="$HOME/.config/nvim"
    TMUX_CONFIG_DIR="$HOME/.config/tmux"
    CONFIG_BASE_DIR="$HOME/.config"
    
    # Create .config directory
    mkdir -p "$CONFIG_BASE_DIR"
    
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
    
    # Check tmux config
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

# Install Nerd Fonts function
install_nerd_fonts() {
    log_info "Installing Nerd Fonts..."
    
    local fonts_dir
    local fonts_installed=false
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        fonts_dir="$HOME/Library/Fonts"
        mkdir -p "$fonts_dir"
        install_fonts_manually "$fonts_dir"
    else
        # Linux
        fonts_dir="$HOME/.local/share/fonts"
        mkdir -p "$fonts_dir"
        install_fonts_manually "$fonts_dir"
    fi
    
    if [[ "$fonts_installed" == true ]] || [[ -n "$(find "$fonts_dir" -name "*Nerd*" -type f 2>/dev/null)" ]]; then
        # Refresh font cache on Linux
        if [[ "$OSTYPE" != "darwin"* ]] && command -v fc-cache >/dev/null 2>&1; then
            log_info "Refreshing font cache..."
            fc-cache -fv >/dev/null 2>&1
        fi
        log_success "Nerd Fonts installation completed"
        log_info "Restart your terminal and set your terminal font to a Nerd Font"
        log_info "Recommended fonts: JetBrainsMono Nerd Font, FiraCode Nerd Font, or Hack Nerd Font"
    else
        log_warning "No Nerd Fonts detected. You may need to install them manually."
    fi
}

# Helper function for manual font installation
install_fonts_manually() {
    local fonts_dir=$1
    local temp_dir="/tmp/nerd-fonts-install"
    
    # Popular Nerd Fonts to install
    local font_downloads=(
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip"
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Meslo.zip"
    )
    
    # Check if any Nerd Fonts are already installed
    if find "$fonts_dir" -name "*Nerd*" -type f | grep -q .; then
        log_success "Nerd Fonts already installed"
        return 0
    fi
    
    log_info "Downloading and installing Nerd Fonts manually..."
    mkdir -p "$temp_dir"
    
    local fonts_downloaded=false
    
    for font_url in "${font_downloads[@]}"; do
        local font_name=$(basename "$font_url" .zip)
        local zip_file="$temp_dir/$font_name.zip"
        
        log_info "Downloading $font_name Nerd Font..."
        if curl -L -f -o "$zip_file" "$font_url" 2>/dev/null; then
            log_info "Extracting $font_name..."
            if command -v unzip >/dev/null 2>&1; then
                unzip -q -j "$zip_file" "*.ttf" "*.otf" -d "$fonts_dir" 2>/dev/null || true
                fonts_downloaded=true
                log_success "$font_name installed"
            else
                log_warning "unzip not available, skipping $font_name"
            fi
        else
            log_warning "Failed to download $font_name"
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [[ "$fonts_downloaded" == false ]]; then
        log_warning "Could not download fonts automatically. Please install manually:"
        log_info "Visit: https://github.com/ryanoasis/nerd-fonts/releases"
        log_info "Download a font zip, extract TTF/OTF files to: $fonts_dir"
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
    install_nerd_fonts
    deploy_configs
    install_tpm
    setup_shell_aliases
    
    echo ""
    log_success "Installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal to load new fonts"
    echo "  2. Set your terminal font to a Nerd Font (e.g., 'JetBrainsMono Nerd Font')"
    echo "  3. Start tmux and press Ctrl+Space + I to install plugins"
    echo "  4. Open nvim to complete NvChad setup"
    echo "  5. Run 'source ~/.zshrc' to use 'vim' alias"
    echo "  6. If you installed nvim via Snap, the PATH has been configured automatically"
    echo ""
    log_info "The setup script can be run multiple times safely."
    
    # Verify nvim is accessible
    echo ""
    if command -v nvim >/dev/null 2>&1; then
        local nvim_version=$(nvim --version | head -n1)
        log_success "Neovim is accessible: $nvim_version"
    else
        log_warning "nvim command not found in current session"
        log_info "Try: source ~/.zshrc (or restart your terminal)"
    fi
    
    # Font installation reminder
    echo ""
    log_info "Font Configuration:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  - Fonts installed to: ~/Library/Fonts"
        echo "  - Configure your terminal: Terminal.app → Preferences → Profiles → Font"
    else
        echo "  - Fonts installed to: ~/.local/share/fonts" 
        echo "  - Configure your terminal font settings to use a Nerd Font"
    fi
    echo "  - Recommended: JetBrainsMono Nerd Font, FiraCode Nerd Font, or Hack Nerd Font"
    echo "  - Font size: 12-14pt for optimal readability"
}

# Run main function
main
