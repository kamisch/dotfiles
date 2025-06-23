# Dotfiles

A comprehensive Neovim and tmux configuration setup with NvChad integration and seamless cross-platform installation.

## Features

- **NvChad Configuration**: Modern Neovim setup with Catppuccin theme
- **Tmux Integration**: Seamless navigation between Neovim and tmux
- **Cross-Platform**: Works on macOS and Linux
- **Plugin Management**: Automated plugin installation
- **Sync Tools**: Keep repository and local configs in sync
- **Comprehensive Documentation**: Guides and cheatsheets included

## Quick Start

```bash
# Clone the repository
git clone <your-repo-url> ~/dotfiles

# Run the setup script
cd ~/dotfiles
./setup.sh

# Start tmux and install plugins
tmux
# Press Ctrl+Space + I to install tmux plugins

# Open Neovim to complete NvChad setup
nvim
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
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The script will:
1. Install Neovim and tmux
2. Backup existing configurations
3. Deploy new configurations
4. Install tmux plugin manager (TPM)

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

## Contributing

1. Make changes to your local configuration
2. Test thoroughly
3. Sync to repository: `./sync.sh to-repo`
4. Commit changes: `git add . && git commit -m "Description"`
5. Push to remote: `git push`

## License

This configuration is provided as-is for personal use. Feel free to fork and modify as needed.

---

**Happy coding!** 🚀