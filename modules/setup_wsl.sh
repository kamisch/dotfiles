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

# Check if running in WSL
check_wsl() {
    if [[ ! -f /proc/version ]] || ! grep -q "microsoft\|WSL" /proc/version; then
        log_error "This script is designed for WSL (Windows Subsystem for Linux) only"
        log_info "Current environment does not appear to be WSL"
        exit 1
    fi
    log_success "WSL environment detected"
}

# Install win32yank
install_win32yank() {
    log_info "Installing win32yank for WSL clipboard integration..."
    
    # Check if win32yank is already installed
    if command -v win32yank.exe >/dev/null 2>&1; then
        log_success "win32yank.exe is already installed"
        return 0
    fi
    
    # Create temp directory
    local temp_dir="/tmp/win32yank-install"
    mkdir -p "$temp_dir"
    
    # Download win32yank
    local download_url="https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip"
    local zip_file="$temp_dir/win32yank-x64.zip"
    
    log_info "Downloading win32yank from GitHub..."
    if ! curl -sL -o "$zip_file" "$download_url"; then
        log_error "Failed to download win32yank"
        log_info "You can manually download from: $download_url"
        return 1
    fi
    
    # Extract win32yank.exe
    log_info "Extracting win32yank.exe..."
    if ! command -v unzip >/dev/null 2>&1; then
        log_info "Installing unzip..."
        sudo apt update && sudo apt install -y unzip
    fi
    
    if ! unzip -p "$zip_file" win32yank.exe > "$temp_dir/win32yank.exe"; then
        log_error "Failed to extract win32yank.exe"
        return 1
    fi
    
    # Make executable and move to system path
    chmod +x "$temp_dir/win32yank.exe"
    
    # Try to install to /usr/local/bin (preferred) or ~/.local/bin (fallback)
    if sudo mv "$temp_dir/win32yank.exe" /usr/local/bin/ 2>/dev/null; then
        log_success "win32yank.exe installed to /usr/local/bin/"
    else
        log_info "Installing to ~/.local/bin/ (no sudo access)"
        mkdir -p "$HOME/.local/bin"
        mv "$temp_dir/win32yank.exe" "$HOME/.local/bin/"
        
        # Add ~/.local/bin to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            log_info "Adding ~/.local/bin to PATH..."
            echo '' >> "$HOME/.bashrc"
            echo '# Add ~/.local/bin to PATH for local binaries' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            
            if [[ -f "$HOME/.zshrc" ]]; then
                echo '' >> "$HOME/.zshrc"
                echo '# Add ~/.local/bin to PATH for local binaries' >> "$HOME/.zshrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            fi
            
            # Export for current session
            export PATH="$HOME/.local/bin:$PATH"
            log_success "Added ~/.local/bin to PATH"
        fi
        
        log_success "win32yank.exe installed to ~/.local/bin/"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Verify installation
    if command -v win32yank.exe >/dev/null 2>&1; then
        log_success "win32yank.exe installation verified"
        return 0
    else
        log_error "win32yank.exe installation failed"
        return 1
    fi
}

# Test win32yank functionality
test_win32yank() {
    log_info "Testing win32yank functionality..."
    
    local test_string="win32yank test $(date)"
    
    # Test copy
    if echo "$test_string" | win32yank.exe -i; then
        log_success "Copy to Windows clipboard: OK"
    else
        log_error "Failed to copy to Windows clipboard"
        return 1
    fi
    
    # Test paste
    local pasted_string
    if pasted_string=$(win32yank.exe -o 2>/dev/null); then
        if [[ "$pasted_string" == "$test_string" ]]; then
            log_success "Paste from Windows clipboard: OK"
        else
            log_warning "Paste test: String mismatch (may be due to line endings)"
        fi
    else
        log_error "Failed to paste from Windows clipboard"
        return 1
    fi
    
    return 0
}

# Configure Neovim init.lua
configure_neovim() {
    log_info "Configuring Neovim clipboard integration..."
    
    local nvim_config_file="$HOME/.config/nvim/init.lua"
    local config_dir="$HOME/.config/nvim"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$config_dir" ]]; then
        log_info "Creating Neovim config directory..."
        mkdir -p "$config_dir"
    fi
    
    # Create init.lua if it doesn't exist
    if [[ ! -f "$nvim_config_file" ]]; then
        log_info "Creating new init.lua file..."
        touch "$nvim_config_file"
    fi
    
    # Check if clipboard configuration already exists
    if grep -q "win32yank" "$nvim_config_file" || grep -q "WslClipboard" "$nvim_config_file"; then
        log_warning "WSL clipboard configuration already exists in init.lua"
        read -p "Do you want to replace it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Neovim configuration"
            return 0
        fi
        
        # Remove existing clipboard configuration
        log_info "Removing existing clipboard configuration..."
        sed -i '/-- WSL clipboard/,/^end$/d' "$nvim_config_file"
        sed -i '/WslClipboard/,/}/d' "$nvim_config_file"
        sed -i '/win32yank/d' "$nvim_config_file"
    fi
    
    # Backup existing config
    if [[ -s "$nvim_config_file" ]]; then
        cp "$nvim_config_file" "$nvim_config_file.backup.$(date +%s)"
        log_info "Backed up existing init.lua"
    fi
    
    # Add clipboard configuration
    log_info "Adding WSL clipboard configuration to init.lua..."
    
    cat >> "$nvim_config_file" << 'EOF'

-- WSL clipboard configuration using win32yank
if vim.fn.has('wsl') == 1 then
    vim.g.clipboard = {
        name = 'WslClipboard',
        copy = {
            ['+'] = 'win32yank.exe -i --crlf',
            ['*'] = 'win32yank.exe -i --crlf',
        },
        paste = {
            ['+'] = 'win32yank.exe -o --lf',
            ['*'] = 'win32yank.exe -o --lf',
        },
        cache_enabled = 0,
    }
end

-- Convenient clipboard key mappings
vim.keymap.set('n', '<leader>y', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set('v', '<leader>y', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set('n', '<leader>Y', '"+Y', { desc = 'Copy line to system clipboard' })
vim.keymap.set('n', '<leader>p', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set('n', '<leader>P', '"+P', { desc = 'Paste from system clipboard (before cursor)' })
vim.keymap.set('v', '<leader>p', '"+p', { desc = 'Paste from system clipboard' })

-- Set clipboard to use system clipboard by default
vim.opt.clipboard = 'unnamedplus'
EOF

    log_success "WSL clipboard configuration added to init.lua"
}

# Show usage instructions
show_instructions() {
    echo ""
    log_success "WSL Neovim clipboard setup completed!"
    echo ""
    log_info "📋 How to use:"
    echo "  • Normal yanks (y, yy, etc.) now copy to Windows clipboard automatically"
    echo "  • Normal pastes (p, P) paste from Windows clipboard"
    echo "  • Leader key mappings added:"
    echo "    - <leader>y  = Copy selection to system clipboard"
    echo "    - <leader>Y  = Copy line to system clipboard"
    echo "    - <leader>p  = Paste from system clipboard"
    echo "    - <leader>P  = Paste before cursor from system clipboard"
    echo ""
    log_info "🧪 Test it:"
    echo "  1. Open nvim and copy some text (yy for a line)"
    echo "  2. Switch to Windows and paste (Ctrl+V)"
    echo "  3. Copy text in Windows (Ctrl+C)"
    echo "  4. Switch back to nvim and paste (p)"
    echo ""
    log_info "🔧 Troubleshooting:"
    echo "  • If clipboard doesn't work, restart your terminal"
    echo "  • Check ':checkhealth provider' in nvim for clipboard status"
    echo "  • Verify win32yank works: echo 'test' | win32yank.exe -i && win32yank.exe -o"
    echo ""
}

# Main function
main() {
    log_info "Starting WSL Neovim clipboard setup..."
    echo ""
    
    check_wsl
    
    if install_win32yank; then
        if test_win32yank; then
            configure_neovim
            show_instructions
        else
            log_error "win32yank test failed. Please check your WSL and Windows integration."
            exit 1
        fi
    else
        log_error "Failed to install win32yank. Cannot continue with Neovim configuration."
        exit 1
    fi
    
    log_success "Setup complete! 🎉"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        echo "WSL Neovim Clipboard Setup Script"
        echo ""
        echo "This script:"
        echo "  • Installs win32yank for WSL-Windows clipboard integration"
        echo "  • Configures Neovim init.lua with proper clipboard settings"
        echo "  • Adds convenient key mappings for clipboard operations"
        echo "  • Tests the clipboard functionality"
        echo ""
        echo "Usage: $0 [--help]"
        echo ""
        echo "Requirements:"
        echo "  • WSL (Windows Subsystem for Linux)"
        echo "  • Internet connection for downloading win32yank"
        echo "  • curl and unzip (will be installed if missing)"
        echo ""
        exit 0
        ;;
    *)
        main
        ;;
esac
