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
    CLAUDE_CONFIG_DIR="$HOME/.claude"
    CONFIG_DIR="$HOME/.config"  # Keep for tmux compatibility
else
    # Unix-like systems (Linux, macOS)
    NVIM_CONFIG_DIR="$HOME/.config/nvim"
    TMUX_CONFIG_DIR="$HOME/.config/tmux"
    CLAUDE_CONFIG_DIR="$HOME/.claude"
    CONFIG_DIR="$HOME/.config"
fi

# Shell config files
ZSHRC_FILE="$HOME/.zshrc"
BASHRC_FILE="$HOME/.bashrc"

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

# Parse selective sync flags
parse_sync_flags() {
    # Default to syncing all if no flags provided
    SYNC_NVIM=true
    SYNC_TMUX=true
    SYNC_CLAUDE=true
    SYNC_ZSH=true
    SYNC_BASH=true

    # If any flags are provided, default all to false and enable only specified ones
    local has_flags=false
    for arg in "$@"; do
        if [[ "$arg" == --* ]]; then
            has_flags=true
            break
        fi
    done

    if [[ "$has_flags" == true ]]; then
        SYNC_NVIM=false
        SYNC_TMUX=false
        SYNC_CLAUDE=false
        SYNC_ZSH=false
        SYNC_BASH=false

        for arg in "$@"; do
            case "$arg" in
                --nvim)
                    SYNC_NVIM=true
                    ;;
                --tmux)
                    SYNC_TMUX=true
                    ;;
                --claude)
                    SYNC_CLAUDE=true
                    ;;
                --zsh)
                    SYNC_ZSH=true
                    ;;
                --bash)
                    SYNC_BASH=true
                    ;;
            esac
        done
    fi
}

# Function to sync from local config to repo
sync_to_repo() {
    log_info "Syncing local configs to repository..."

    # Sync nvim config
    if [[ "$SYNC_NVIM" == true ]]; then
        if [[ -d "$NVIM_CONFIG_DIR" ]]; then
            log_info "Syncing nvim config from $NVIM_CONFIG_DIR..."
            rsync -av --delete "$NVIM_CONFIG_DIR/" "$SCRIPT_DIR/config/nvim/"
            log_success "nvim config synced"
        else
            log_warning "No nvim config found at $NVIM_CONFIG_DIR"
        fi
    else
        log_info "Skipping nvim config (not selected)"
    fi

    # Sync tmux config
    if [[ "$SYNC_TMUX" == true ]]; then
        if [[ -d "$TMUX_CONFIG_DIR" ]]; then
            log_info "Syncing tmux config from $TMUX_CONFIG_DIR..."
            rsync -av --delete "$TMUX_CONFIG_DIR/" "$SCRIPT_DIR/config/tmux/"
            log_success "tmux config synced"
        else
            log_warning "No tmux config found at $TMUX_CONFIG_DIR"
        fi
    else
        log_info "Skipping tmux config (not selected)"
    fi

    # Sync claude config
    # Note: Marketplace plugins (plugins/marketplaces/) are excluded from sync because:
    # - They contain git repositories that cause conflicts
    # - They are tracked in known_marketplaces.json and can be reinstalled by Claude Code
    # - This keeps the dotfiles repo clean and avoids nested git repo issues
    if [[ "$SYNC_CLAUDE" == true ]]; then
        if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
            log_info "Syncing claude config from $CLAUDE_CONFIG_DIR..."
            mkdir -p "$SCRIPT_DIR/config/claude"

            # Sync specific files and directories we care about
            if [[ -f "$CLAUDE_CONFIG_DIR/claude.md" ]]; then
                cp "$CLAUDE_CONFIG_DIR/claude.md" "$SCRIPT_DIR/config/claude/"
            fi
            if [[ -f "$CLAUDE_CONFIG_DIR/settings.local.json" ]]; then
                cp "$CLAUDE_CONFIG_DIR/settings.local.json" "$SCRIPT_DIR/config/claude/"
            fi
            if [[ -d "$CLAUDE_CONFIG_DIR/commands" ]]; then
                rsync -av --delete "$CLAUDE_CONFIG_DIR/commands/" "$SCRIPT_DIR/config/claude/commands/"
            fi
            if [[ -d "$CLAUDE_CONFIG_DIR/plugins" ]]; then
                # Exclude marketplaces - they contain git repos and are reinstallable from known_marketplaces.json
                rsync -av --delete --exclude='marketplaces' "$CLAUDE_CONFIG_DIR/plugins/" "$SCRIPT_DIR/config/claude/plugins/"
            fi

            log_success "claude config synced"
        else
            log_warning "No claude config found at $CLAUDE_CONFIG_DIR"
        fi
    else
        log_info "Skipping claude config (not selected)"
    fi

    # Sync shell configs
    if [[ "$SYNC_ZSH" == true ]]; then
        mkdir -p "$SCRIPT_DIR/shell"

        if [[ -f "$ZSHRC_FILE" ]]; then
            log_info "Syncing .zshrc from $ZSHRC_FILE..."
            cp "$ZSHRC_FILE" "$SCRIPT_DIR/shell/.zshrc"
            log_success ".zshrc synced"
        else
            log_warning "No .zshrc found at $ZSHRC_FILE"
        fi
    else
        log_info "Skipping .zshrc config (not selected)"
    fi

    if [[ "$SYNC_BASH" == true ]]; then
        mkdir -p "$SCRIPT_DIR/shell"

        if [[ -f "$BASHRC_FILE" ]]; then
            log_info "Syncing .bashrc from $BASHRC_FILE..."
            cp "$BASHRC_FILE" "$SCRIPT_DIR/shell/.bashrc"
            log_success ".bashrc synced"
        else
            log_warning "No .bashrc found at $BASHRC_FILE"
        fi
    else
        log_info "Skipping .bashrc config (not selected)"
    fi
}

# Function to sync from repo to local config
# Uses --ignore-existing to preserve local modifications (won't overwrite existing files)
# Uses --delete to remove files that no longer exist in repo (cleanup)
# This means: new files are added, old files are removed, but existing files are preserved
sync_from_repo() {
    log_info "Syncing repository configs to local..."

    # Create backup first
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

    # Backup nvim if exists and will be synced
    if [[ "$SYNC_NVIM" == true && -d "$NVIM_CONFIG_DIR" ]]; then
        log_info "Backing up current nvim config..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$NVIM_CONFIG_DIR" "$BACKUP_DIR/"
    fi

    # Backup tmux if exists and will be synced
    if [[ "$SYNC_TMUX" == true && -d "$TMUX_CONFIG_DIR" ]]; then
        log_info "Backing up current tmux config..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$TMUX_CONFIG_DIR" "$BACKUP_DIR/"
    fi

    # Backup claude if exists and will be synced
    if [[ "$SYNC_CLAUDE" == true && -d "$CLAUDE_CONFIG_DIR" ]]; then
        log_info "Backing up current claude config..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$CLAUDE_CONFIG_DIR" "$BACKUP_DIR/"
    fi

    # Backup shell configs if they exist and will be synced
    if [[ "$SYNC_ZSH" == true && -f "$ZSHRC_FILE" ]]; then
        log_info "Backing up current .zshrc..."
        mkdir -p "$BACKUP_DIR"
        cp "$ZSHRC_FILE" "$BACKUP_DIR/.zshrc"
    fi

    if [[ "$SYNC_BASH" == true && -f "$BASHRC_FILE" ]]; then
        log_info "Backing up current .bashrc..."
        mkdir -p "$BACKUP_DIR"
        cp "$BASHRC_FILE" "$BACKUP_DIR/.bashrc"
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

    # Sync nvim config
    if [[ "$SYNC_NVIM" == true ]]; then
        if [[ -d "$SCRIPT_DIR/config/nvim" ]]; then
            log_info "Syncing nvim config from repo to $NVIM_CONFIG_DIR..."
            rsync -av --ignore-existing --delete "$SCRIPT_DIR/config/nvim/" "$NVIM_CONFIG_DIR/"
            log_success "nvim config synced from repo"
        fi
    else
        log_info "Skipping nvim config (not selected)"
    fi

    # Sync tmux config
    if [[ "$SYNC_TMUX" == true ]]; then
        if [[ -d "$SCRIPT_DIR/config/tmux" ]]; then
            log_info "Syncing tmux config from repo to $TMUX_CONFIG_DIR..."
            rsync -av --ignore-existing --delete "$SCRIPT_DIR/config/tmux/" "$TMUX_CONFIG_DIR/"
            log_success "tmux config synced from repo"
        fi
    else
        log_info "Skipping tmux config (not selected)"
    fi

    # Sync claude config from repo
    if [[ "$SYNC_CLAUDE" == true ]]; then
        if [[ -d "$SCRIPT_DIR/config/claude" ]]; then
            log_info "Syncing claude config from repo to $CLAUDE_CONFIG_DIR..."
            mkdir -p "$CLAUDE_CONFIG_DIR"

            # Sync specific files and directories
            if [[ -f "$SCRIPT_DIR/config/claude/claude.md" ]]; then
                cp "$SCRIPT_DIR/config/claude/claude.md" "$CLAUDE_CONFIG_DIR/"
            fi
            if [[ -f "$SCRIPT_DIR/config/claude/settings.local.json" ]]; then
                cp "$SCRIPT_DIR/config/claude/settings.local.json" "$CLAUDE_CONFIG_DIR/"
            fi
            if [[ -d "$SCRIPT_DIR/config/claude/commands" ]]; then
                rsync -av --ignore-existing --delete "$SCRIPT_DIR/config/claude/commands/" "$CLAUDE_CONFIG_DIR/commands/"
            fi
            if [[ -d "$SCRIPT_DIR/config/claude/plugins" ]]; then
                # Exclude marketplaces - they contain git repos and are reinstallable from known_marketplaces.json
                # Using --ignore-existing to preserve locally installed marketplace plugins
                rsync -av --ignore-existing --exclude='marketplaces' "$SCRIPT_DIR/config/claude/plugins/" "$CLAUDE_CONFIG_DIR/plugins/"
            fi

            log_success "claude config synced from repo"
        fi
    else
        log_info "Skipping claude config (not selected)"
    fi

    # Sync shell configs from repo
    if [[ "$SYNC_ZSH" == true ]]; then
        if [[ -f "$SCRIPT_DIR/shell/.zshrc" ]]; then
            log_info "Syncing .zshrc from repo to $ZSHRC_FILE..."
            cp "$SCRIPT_DIR/shell/.zshrc" "$ZSHRC_FILE"
            log_success ".zshrc synced from repo"
        fi
    else
        log_info "Skipping .zshrc config (not selected)"
    fi

    if [[ "$SYNC_BASH" == true ]]; then
        if [[ -f "$SCRIPT_DIR/shell/.bashrc" ]]; then
            log_info "Syncing .bashrc from repo to $BASHRC_FILE..."
            cp "$SCRIPT_DIR/shell/.bashrc" "$BASHRC_FILE"
            log_success ".bashrc synced from repo"
        fi
    else
        log_info "Skipping .bashrc config (not selected)"
    fi
}

# Function to show diff between local and repo
show_diff() {
    log_info "Showing differences between local config and repository..."

    if [[ "$SYNC_NVIM" == true ]]; then
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
    fi

    if [[ "$SYNC_TMUX" == true ]]; then
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
    fi

    if [[ "$SYNC_CLAUDE" == true ]]; then
        echo
        echo "=== CLAUDE DIFFERENCES ==="
        if [[ -d "$CLAUDE_CONFIG_DIR" && -d "$SCRIPT_DIR/config/claude" ]]; then
            if ! diff -rq "$CLAUDE_CONFIG_DIR" "$SCRIPT_DIR/config/claude" >/dev/null 2>&1; then
                diff -ru "$SCRIPT_DIR/config/claude" "$CLAUDE_CONFIG_DIR" || true
            else
                log_success "claude configs are identical"
            fi
        else
            log_warning "Cannot compare claude configs - one or both directories missing"
            log_info "Local claude config: $CLAUDE_CONFIG_DIR"
            log_info "Repo claude config: $SCRIPT_DIR/config/claude"
        fi
    fi

    if [[ "$SYNC_ZSH" == true ]]; then
        echo
        echo "=== ZSHRC DIFFERENCES ==="
        if [[ -f "$ZSHRC_FILE" && -f "$SCRIPT_DIR/shell/.zshrc" ]]; then
            if ! diff -q "$ZSHRC_FILE" "$SCRIPT_DIR/shell/.zshrc" >/dev/null 2>&1; then
                diff -u "$SCRIPT_DIR/shell/.zshrc" "$ZSHRC_FILE" || true
            else
                log_success ".zshrc configs are identical"
            fi
        else
            log_warning "Cannot compare .zshrc configs - one or both files missing"
            log_info "Local .zshrc: $ZSHRC_FILE"
            log_info "Repo .zshrc: $SCRIPT_DIR/shell/.zshrc"
        fi
    fi

    if [[ "$SYNC_BASH" == true ]]; then
        echo
        echo "=== BASHRC DIFFERENCES ==="
        if [[ -f "$BASHRC_FILE" && -f "$SCRIPT_DIR/shell/.bashrc" ]]; then
            if ! diff -q "$BASHRC_FILE" "$SCRIPT_DIR/shell/.bashrc" >/dev/null 2>&1; then
                diff -u "$SCRIPT_DIR/shell/.bashrc" "$BASHRC_FILE" || true
            else
                log_success ".bashrc configs are identical"
            fi
        else
            log_warning "Cannot compare .bashrc configs - one or both files missing"
            log_info "Local .bashrc: $BASHRC_FILE"
            log_info "Repo .bashrc: $SCRIPT_DIR/shell/.bashrc"
        fi
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
    echo "Dotfiles Sync Script (nvim + tmux + claude + shell)"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  to-repo     Sync local configs to repository (local -> repo)"
    echo "  from-repo   Sync repository configs to local (repo -> local)"
    echo "  diff        Show differences between local and repo configs"
    echo "  status      Show git status (if in git repository)"
    echo "  help        Show this help message"
    echo ""
    echo "Options (for to-repo, from-repo, and diff commands):"
    echo "  --nvim      Only sync/diff nvim configuration"
    echo "  --tmux      Only sync/diff tmux configuration"
    echo "  --claude    Only sync/diff claude configuration"
    echo "  --zsh       Only sync/diff .zshrc configuration"
    echo "  --bash      Only sync/diff .bashrc configuration"
    echo ""
    echo "  Note: If no options are specified, ALL configs will be synced (default behavior)."
    echo "        If ANY option is specified, ONLY those configs will be synced."
    echo "        Multiple options can be combined."
    echo ""
    echo "Configurations:"
    echo "  • nvim   - Neovim config directory"
    echo "  • tmux   - Tmux config directory"
    echo "  • claude - Claude config directory (settings, commands, plugins)"
    echo "  • zsh    - .zshrc file"
    echo "  • bash   - .bashrc file"
    echo ""
    echo "Examples:"
    echo "  $0 to-repo                    # Sync ALL configs to repo"
    echo "  $0 from-repo                  # Sync ALL configs from repo"
    echo "  $0 to-repo --nvim             # Sync ONLY nvim config to repo"
    echo "  $0 from-repo --claude         # Sync ONLY claude config from repo"
    echo "  $0 to-repo --nvim --tmux      # Sync ONLY nvim and tmux to repo"
    echo "  $0 diff --claude              # Show ONLY claude config differences"
    echo "  $0 diff                       # Show ALL config differences"
    echo ""
}

# Main function
main() {
    # Extract command (first argument)
    local command="${1:-help}"

    # Parse flags (all arguments after the first)
    shift 2>/dev/null || true
    parse_sync_flags "$@"

    case "$command" in
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
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
