#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine config paths based on OS
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
    # Windows paths
    NVIM_CONFIG_DIR="$HOME/AppData/Local/nvim"
    TMUX_CONFIG_DIR="$HOME/.config/tmux"
    CONFIG_DIR="$HOME/.config"  # Keep for tmux compatibility
else
    # Unix-like systems (Linux, macOS)
    NVIM_CONFIG_DIR="$HOME/.config/nvim"
    TMUX_CONFIG_DIR="$HOME/.config/tmux"
    CONFIG_DIR="$HOME/.config"
fi

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

# Function to sync from local config to repo
sync_to_repo() {
    log_info "Syncing local configs to repository..."
    
    # Sync nvim config
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        log_info "Syncing nvim config from $NVIM_CONFIG_DIR..."
        rsync -av --delete "$NVIM_CONFIG_DIR/" "$SCRIPT_DIR/config/nvim/"
        log_success "nvim config synced"
    else
        log_warning "No nvim config found at $NVIM_CONFIG_DIR"
    fi
    
    # Sync tmux config  
    if [[ -d "$TMUX_CONFIG_DIR" ]]; then
        log_info "Syncing tmux config from $TMUX_CONFIG_DIR..."
        rsync -av --delete "$TMUX_CONFIG_DIR/" "$SCRIPT_DIR/config/tmux/"
        log_success "tmux config synced"
    else
        log_warning "No tmux config found at $TMUX_CONFIG_DIR"
    fi
}

# Function to sync from repo to local config
sync_from_repo() {
    log_info "Syncing repository configs to local..."
    
    # Create backup first
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    
    # Backup nvim if exists
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        log_info "Backing up current nvim config..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$NVIM_CONFIG_DIR" "$BACKUP_DIR/"
    fi
    
    # Backup tmux if exists
    if [[ -d "$TMUX_CONFIG_DIR" ]]; then
        log_info "Backing up current tmux config..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$TMUX_CONFIG_DIR" "$BACKUP_DIR/"
    fi
    
    if [[ -d "$BACKUP_DIR" ]]; then
        log_success "Backup created at: $BACKUP_DIR"
    fi
    
    # Sync from repo - create necessary directories based on OS
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        mkdir -p "$HOME/AppData/Local"
        mkdir -p "$HOME/.config"
    else
        mkdir -p "$CONFIG_DIR"
    fi
    
    if [[ -d "$SCRIPT_DIR/config/nvim" ]]; then
        log_info "Syncing nvim config from repo to $NVIM_CONFIG_DIR..."
        rsync -av --delete "$SCRIPT_DIR/config/nvim/" "$NVIM_CONFIG_DIR/"
        log_success "nvim config synced from repo"
    fi
    
    if [[ -d "$SCRIPT_DIR/config/tmux" ]]; then
        log_info "Syncing tmux config from repo to $TMUX_CONFIG_DIR..."
        rsync -av --delete "$SCRIPT_DIR/config/tmux/" "$TMUX_CONFIG_DIR/"
        log_success "tmux config synced from repo"
    fi
}

# Function to show diff between local and repo
show_diff() {
    log_info "Showing differences between local config and repository..."
    
    echo
    echo "=== NVIM DIFFERENCES ==="
    if [[ -d "$NVIM_CONFIG_DIR" && -d "$SCRIPT_DIR/config/nvim" ]]; then
        if ! diff -rq "$NVIM_CONFIG_DIR" "$SCRIPT_DIR/config/nvim" >/dev/null 2>&1; then
            diff -ru "$SCRIPT_DIR/config/nvim" "$NVIM_CONFIG_DIR" || true
        else
            log_success "nvim configs are identical"
        fi
    else
        log_warning "Cannot compare nvim configs - one or both directories missing"
        log_info "Local nvim config: $NVIM_CONFIG_DIR"
        log_info "Repo nvim config: $SCRIPT_DIR/config/nvim"
    fi
    
    echo
    echo "=== TMUX DIFFERENCES ==="
    if [[ -d "$TMUX_CONFIG_DIR" && -d "$SCRIPT_DIR/config/tmux" ]]; then
        if ! diff -rq "$TMUX_CONFIG_DIR" "$SCRIPT_DIR/config/tmux" >/dev/null 2>&1; then
            diff -ru "$SCRIPT_DIR/config/tmux" "$TMUX_CONFIG_DIR" || true
        else
            log_success "tmux configs are identical"
        fi
    else
        log_warning "Cannot compare tmux configs - one or both directories missing"
        log_info "Local tmux config: $TMUX_CONFIG_DIR"
        log_info "Repo tmux config: $SCRIPT_DIR/config/tmux"
    fi
}

# Function to check git status if in git repo
check_git_status() {
    if [[ -d "$SCRIPT_DIR/.git" ]]; then
        log_info "Git status:"
        cd "$SCRIPT_DIR"
        git status --porcelain
        
        if [[ -n $(git status --porcelain) ]]; then
            log_warning "Repository has uncommitted changes"
            echo "Run 'git add . && git commit -m \"Update configs\"' to commit changes"
        else
            log_success "Repository is clean"
        fi
    fi
}

# Show help
show_help() {
    echo "Dotfiles Sync Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  to-repo     Sync local configs to repository (local -> repo)"
    echo "  from-repo   Sync repository configs to local (repo -> local)"
    echo "  diff        Show differences between local and repo configs"
    echo "  status      Show git status (if in git repository)"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 to-repo      # Update repo with your local changes"
    echo "  $0 from-repo    # Update local config from repo"
    echo "  $0 diff         # See what's different"
    echo ""
}

# Main function
main() {
    case "${1:-help}" in
        "to-repo")
            sync_to_repo
            check_git_status
            ;;
        "from-repo")
            sync_from_repo
            ;;
        "diff")
            show_diff
            ;;
        "status")
            check_git_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"