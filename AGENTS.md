# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing Neovim, tmux, and Claude Code configurations across macOS, Linux, and Windows platforms. The repository uses a modular architecture with setup scripts and sync utilities to maintain consistency between the repository and local system configurations.

## Repository Structure

```
dotfiles/
├── modules/                   # Core setup and configuration modules
│   ├── config/
│   │   ├── nvim/             # NvChad-based Neovim configuration
│   │   ├── tmux/             # Tmux configuration with Catppuccin theme
│   │   └── claude/           # Claude Code configuration and commands
│   ├── setup_editor.sh       # Editor (Neovim/tmux) setup module
│   ├── setup_node_env.sh     # Node.js environment setup
│   ├── setup_wsl.sh          # WSL-specific setup
│   ├── sync.sh               # Bidirectional sync between repo and local configs
│   └── zsh_setup.sh          # Zsh configuration setup
├── tests/                     # Comprehensive test suite with Docker support
├── docs/                      # User documentation and guides
└── README.md                  # Primary documentation
```

## Common Development Commands

### Configuration Management

```bash
# Sync local configs to repository
./modules/sync.sh to-repo

# Sync repository to local configs
./modules/sync.sh from-repo

# View differences between repo and local configs
./modules/sync.sh diff

# Check git status
./modules/sync.sh status
```

### Testing

```bash
# Test on Ubuntu (default)
./tests/run-tests.sh

# Test on all environments (Ubuntu + Alpine)
./tests/run-tests.sh --all

# Test locally with backup/restore
./tests/run-tests.sh --local

# Clean up Docker resources
./tests/run-tests.sh --clean
```

### Setup Scripts

```bash
# Run editor setup (Neovim + tmux)
./modules/setup_editor.sh [--force]

# Run zsh setup
./modules/zsh_setup.sh

# Run Node.js environment setup
./modules/setup_node_env.sh
```

## Architecture Notes

### Configuration Deployment Strategy

The repository uses a **modular, idempotent setup** approach:

1. **Platform Detection**: Scripts detect OS type (macOS, Linux, Windows) and set appropriate config paths
   - macOS/Linux: `~/.config/nvim`, `~/.config/tmux`, `~/.claude`
   - Windows: `~/AppData/Local/nvim`, `~/.config/tmux`, `~/.claude`

2. **Idempotent Installation**: Setup scripts can be run multiple times safely:
   - Checks if configs are identical before copying
   - Only creates backups when changes are detected
   - Uses `--force` flag to override protection

3. **Sync Architecture**: Bidirectional synchronization between repository and system:
   - `to-repo`: Copies from system locations to `modules/config/`
   - `from-repo`: Deploys from `modules/config/` to system locations
   - Uses `rsync` with exclusions for generated files

### Neovim Configuration (NvChad v2.5)

- **Base**: NvChad framework with Lazy.nvim plugin manager
- **Theme**: Catppuccin
- **LSP Servers**: html, cssls, pyright, ruff, hadolint, gdscript, clangd (see `modules/config/nvim/lua/configs/lspconfig.lua:3`)
- **Key Integration**: vim-tmux-navigator for seamless tmux navigation (see `modules/config/nvim/lua/mappings.lua:13-17`)
- **Plugin Structure**: Modular plugins in `lua/plugins/` directory

### Tmux Configuration

- **Prefix**: `Ctrl+Space` (not default `Ctrl+b`)
- **Plugins**: TPM, vim-tmux-navigator, Catppuccin, tmux-yank, tmux-resurrect, tmux-continuum
- **Session Persistence**: Resurrect saves to `~/code/tmux-resurrect`, auto-restore enabled
- **Navigation**: Integrated with Neovim via `Ctrl+h/j/k/l` (see `modules/config/tmux/tmux.conf:20`)
- **Claude Integration**: `<prefix>a` opens Claude Code in popup (see `modules/config/tmux/tmux.conf:42`)

### Testing Infrastructure

The test suite validates cross-platform functionality:
- **Docker Tests**: Ubuntu 22.04 and Alpine Linux containers
- **Local Tests**: Backup/restore mechanism for safe testing
- **Coverage**: Setup idempotency, sync bidirectionality, package installation, config integrity

## Important Files

### Configuration Entry Points
- `modules/config/nvim/init.lua` - Neovim initialization
- `modules/config/nvim/lua/plugins/init.lua` - Plugin definitions
- `modules/config/nvim/lua/mappings.lua` - Custom keybindings
- `modules/config/tmux/tmux.conf` - Tmux configuration
- `modules/config/claude/claude.md` - Claude Code workspace instructions

### Setup Scripts
- `modules/setup_editor.sh` - Main editor setup logic
- `modules/sync.sh` - Configuration synchronization
- `tests/test-suite.sh` - Comprehensive test suite

### Documentation
- `docs/cheatsheet.md` - Quick reference for commands
- `docs/nvchad-guide.md` - Detailed Neovim guide
- `docs/tmux-guide.md` - Comprehensive tmux documentation

## Development Workflow

### Making Configuration Changes

1. **Edit configs** in `modules/config/`
2. **Test locally** by running setup: `./modules/setup_editor.sh --force`
3. **Verify** in Neovim/tmux
4. **Run tests**: `./tests/run-tests.sh --all`
5. **Commit changes** with descriptive message

### Modifying Setup Logic

1. **Edit module scripts** in `modules/`
2. **Test thoroughly** using test suite
3. **Update documentation** if behavior changes
4. **Verify idempotent behavior** (run setup multiple times)

### Adding Neovim Plugins

1. **Add plugin spec** to `modules/config/nvim/lua/plugins/init.lua` or create new file in `lua/plugins/`
2. **Configure plugin** in appropriate lua file
3. **Restart Neovim** to trigger Lazy.nvim installation
4. **Sync to repo**: `./modules/sync.sh to-repo`

### Adding Tmux Plugins

1. **Add plugin line** to `modules/config/tmux/tmux.conf`: `set -g @plugin 'author/plugin'`
2. **Reload tmux**: `tmux source ~/.config/tmux/tmux.conf`
3. **Install plugins**: Press `Ctrl+Space` then `I`
4. **Sync to repo**: `./modules/sync.sh to-repo`

## Notes for AI Assistants

- **No root setup.sh**: The README references `setup.sh` but it doesn't exist at root; use `modules/setup_editor.sh` instead
- **Platform-specific paths**: Always check OS type before assuming config paths
- **Idempotent design**: All setup scripts should be safe to run multiple times
- **Sync before edit**: Use `./modules/sync.sh from-repo` to ensure latest configs before making changes
- **Test suite is comprehensive**: Always run tests before committing setup script changes
- **LSP configuration**: Enabled servers are hardcoded in lspconfig.lua, not auto-installed
- **Tmux prefix changed**: Not `Ctrl+b`, it's `Ctrl+Space`
