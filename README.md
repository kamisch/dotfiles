# Dotfiles

A comprehensive Neovim and tmux configuration setup with NvChad integration and seamless cross-platform installation.

## Features

- **NvChad Configuration**: Modern Neovim setup with Catppuccin theme
- **Tmux Integration**: Seamless navigation between Neovim and tmux
- **Cross-Platform**: Works on macOS and Linux
- **Plugin Management**: Automated plugin installation
- **Shell Integration**: Automatic `vim=nvim` alias setup for zsh and bash
- **Idempotent Setup**: Run setup script multiple times safely
- **Sync Tools**: Keep repository and local configs in sync
- **Comprehensive Documentation**: Guides and cheatsheets included

## Quick Start

```bash
# Clone the repository
git clone https://github.com/kamisch/dotfiles.git ~/dotfiles

# Run the setup script
cd ~/dotfiles
./setup.sh

# The script is idempotent - you can run it multiple times safely
# Use --force to reinstall configs even if they exist
./setup.sh --force

# Restart your terminal to use the vim alias
# Or reload your shell: source ~/.zshrc (or ~/.bashrc)

# Start tmux and install plugins
tmux
# Press Ctrl+Space + I to install tmux plugins

# Open Neovim to complete NvChad setup
vim  # Now uses nvim thanks to the alias!
```

## Repository Structure

```
dotfiles/
├── setup.sh              # Main installation script
├── sync.sh               # Sync local configs with repo
├── config/
│   ├── nvim/             # NvChad configuration
│   └── tmux/             # Tmux configuration
├── docs/
│   ├── cheatsheet.md     # Developer cheatsheet
│   ├── nvchad-guide.md   # NvChad documentation
│   └── tmux-guide.md     # Tmux documentation
└── README.md             # This file
```

## Installation

### Prerequisites

The setup script will install these automatically, but you can install them manually:

**macOS:**
```bash
brew install neovim tmux git
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install neovim tmux git curl
```

**Linux (Arch):**
```bash
sudo pacman -S neovim tmux git curl
```

### Automated Installation

```bash
# Clone and setup
git clone https://github.com/kamisch/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh

# Optional: Force reinstall even if configs exist
./setup.sh --force

# Get help
./setup.sh --help
```

The script will:
1. Install Neovim and tmux (if not already installed)
2. Deploy configurations (only if different or missing)
3. Backup existing configurations before overwriting
4. Install tmux plugin manager (TPM) if not present
5. Setup `vim=nvim` alias in shell configurations (if not already set)
6. Skip steps that are already completed (idempotent)

## Configuration Details

### Neovim (NvChad)
- **Framework**: NvChad v2.5
- **Theme**: Catppuccin
- **Plugin Manager**: Lazy.nvim
- **LSP**: Configured for multiple languages
- **Key Features**: File explorer, fuzzy finder, git integration

### Tmux
- **Prefix**: `Ctrl+Space`
- **Theme**: Catppuccin (matches Neovim)
- **Plugins**: vim-tmux-navigator, tmux-yank, tmux-sensible
- **Features**: Mouse support, vim-style copy mode, system clipboard integration

## Usage

### Essential Commands

**Neovim:**
- `<Space>ff` - Find files
- `<Space>fw` - Find text in files
- `<Space>e` - Toggle file explorer
- `Ctrl+h/j/k/l` - Navigate between splits/tmux panes

**Tmux:**
- `Ctrl+Space` - Prefix key
- `<prefix>c` - New window
- `<prefix>"` - Split horizontally
- `<prefix>%` - Split vertically
- `Ctrl+h/j/k/l` - Navigate between panes/nvim splits

### Sync Configuration

Keep your repository and local configs synchronized:

```bash
# Update repo with local changes
./sync.sh to-repo

# Update local config from repo
./sync.sh from-repo

# Show differences
./sync.sh diff

# Check git status
./sync.sh status
```

## Documentation

- **[Developer Cheatsheet](docs/cheatsheet.md)** - Essential commands and workflows
- **[NvChad Guide](docs/nvchad-guide.md)** - Detailed Neovim configuration guide
- **[Tmux Guide](docs/tmux-guide.md)** - Comprehensive tmux documentation

## Customization

### Adding Neovim Plugins

1. Edit `config/nvim/lua/plugins/init.lua`
2. Add your plugin specification
3. Restart Neovim
4. Sync changes: `./sync.sh to-repo`

### Adding Tmux Plugins

1. Edit `config/tmux/tmux.conf`
2. Add `set -g @plugin 'plugin-name'`
3. Reload tmux: `tmux source ~/.config/tmux/tmux.conf`
4. Install plugins: `<prefix>I`
5. Sync changes: `./sync.sh to-repo`

### Custom Keybindings

**Neovim:** Edit `config/nvim/lua/mappings.lua`
**Tmux:** Edit `config/tmux/tmux.conf`

## Troubleshooting

### Setup Script Issues

1. **Setup script fails**
   ```bash
   # Run with more verbose output
   bash -x ./setup.sh
   
   # Check help for options
   ./setup.sh --help
   ```

2. **Configs not updating**
   ```bash
   # Force reinstall configurations
   ./setup.sh --force
   
   # Check differences first
   ./sync.sh diff
   ```

3. **Multiple backups accumulating**
   - The script only backs up when configs are different
   - Clean old backups: `rm -rf ~/.config/*.backup.*`

### Common Issues

1. **Colors not displaying correctly**
   ```bash
   echo $TERM  # Should show screen-256color or similar
   ```

2. **Plugins not installing**
   ```bash
   # Neovim
   :Lazy update
   
   # Tmux
   ~/.tmux/plugins/tpm/bin/install_plugins
   ```

3. **Navigation between Neovim and tmux not working**
   - Ensure vim-tmux-navigator is installed in both
   - Check keybinding conflicts

### Getting Help

- Check the documentation in `docs/`
- Run `:checkhealth` in Neovim
- Use `tmux info` for tmux diagnostics
- Run `./setup.sh --help` for setup options

## Backup and Recovery

### Automatic Backups
The setup script automatically backs up existing configurations to `~/.config-backup-TIMESTAMP`

### Manual Backup
```bash
cp -r ~/.config/nvim ~/.config/nvim.backup
cp -r ~/.config/tmux ~/.config/tmux.backup
```

### Recovery
```bash
# Restore from backup
mv ~/.config/nvim.backup ~/.config/nvim
mv ~/.config/tmux.backup ~/.config/tmux
```

## Testing

A comprehensive test suite validates the functionality across different environments:

```bash
# Test on Ubuntu (default)
./tests/run-tests.sh

# Test on all environments
./tests/run-tests.sh --all

# Test locally (with backup/restore)
./tests/run-tests.sh --local

# Clean up Docker resources
./tests/run-tests.sh --clean
```

### What's Tested
- ✅ Package installation (Neovim, tmux, git)
- ✅ Configuration deployment and integrity
- ✅ Idempotent behavior (safe repeated runs)
- ✅ Force flag functionality
- ✅ Sync script bidirectional operation
- ✅ Shell alias setup
- ✅ Backup and restore mechanisms

See [`tests/README.md`](tests/README.md) for detailed testing documentation.

## Contributing

1. Make changes to your local configuration
2. Test thoroughly: `./tests/run-tests.sh --all`
3. Sync to repository: `./sync.sh to-repo`
4. Commit changes: `git add . && git commit -m "Description"`
5. Push to remote: `git push`

## License

This configuration is provided as-is for personal use. Feel free to fork and modify as needed.

---

**Happy coding!** 🚀