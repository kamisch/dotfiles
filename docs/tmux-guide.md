# Tmux Configuration Guide

## Overview
This tmux configuration provides a modern, vim-friendly terminal multiplexer setup with useful plugins and seamless Neovim integration.

## Configuration Structure

```
~/.config/tmux/
├── tmux.conf           # Main configuration file
└── plugins/            # Plugin directory (managed by TPM)
    ├── tpm/            # Tmux Plugin Manager
    ├── tmux-sensible/  # Sensible defaults
    ├── vim-tmux-navigator/  # Vim/tmux navigation
    ├── tmux/           # Catppuccin theme
    └── tmux-yank/      # System clipboard integration
```

## Key Configuration Features

### Prefix Key
- **Prefix**: `Ctrl+Space` (instead of default `Ctrl+b`)
- More ergonomic and doesn't conflict with other shortcuts

### True Color Support
```bash
set -g default-terminal "screen-256color"
```
- Enables full color support for modern terminals
- Essential for proper theme rendering

### Mouse Support
```bash
set -g mouse on
```
- Click to select panes and windows
- Resize panes by dragging borders
- Scroll through history

### Window/Pane Indexing
```bash
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on
```
- Windows and panes start from 1 (not 0)
- Automatically renumber windows when one is closed

### Vi Mode
```bash
set-window-option -g mode-keys vi
```
- Vim-like keybindings in copy mode
- Familiar navigation for vim users

## Installed Plugins

### 1. TPM (Tmux Plugin Manager)
- **Purpose**: Manages tmux plugins
- **Commands**:
  - `<prefix>I` - Install plugins
  - `<prefix>U` - Update plugins
  - `<prefix>alt+u` - Remove unused plugins

### 2. tmux-sensible
- **Purpose**: Sensible default settings
- **Features**:
  - Better default key bindings
  - Improved scrolling
  - Enhanced mouse support
  - Proper terminal settings

### 3. vim-tmux-navigator
- **Purpose**: Seamless navigation between vim/nvim and tmux
- **Keybindings**:
  - `Ctrl+h` - Move left
  - `Ctrl+j` - Move down
  - `Ctrl+k` - Move up
  - `Ctrl+l` - Move right
  - `Ctrl+\` - Move to previous pane

### 4. Catppuccin Theme
- **Purpose**: Beautiful, consistent theming
- **Features**:
  - Matches NvChad theme
  - Multiple color variants
  - Customizable status line

### 5. tmux-yank
- **Purpose**: Copy to system clipboard
- **Features**:
  - Automatic clipboard integration
  - Works with various operating systems
  - Vi-mode copy enhancements

## Custom Key Bindings

### Pane Splitting
```bash
bind '"' split-window -v -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
```
- New panes open in current directory
- Maintains directory context

### Copy Mode (Vi-style)
```bash
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
```
- `v` - Start visual selection
- `Ctrl+v` - Rectangle (block) selection
- `y` - Copy selection and exit copy mode

## Usage Patterns

### 1. Session Management
```bash
# Create named session
tmux new-session -s project-name

# Detach from session
<prefix>d

# List sessions
tmux list-sessions

# Attach to session
tmux attach-session -t project-name

# Switch between sessions
<prefix>s
```

### 2. Window Management
```bash
# Create new window
<prefix>c

# Rename window
<prefix>,

# Switch to window by number
<prefix>0-9

# Next/previous window
<prefix>n / <prefix>p

# Kill window
<prefix>&
```

### 3. Pane Management
```bash
# Split horizontally (new pane below)
<prefix>"

# Split vertically (new pane to right)
<prefix>%

# Navigate panes
Ctrl+h/j/k/l

# Resize panes
<prefix>Ctrl+h/j/k/l

# Zoom pane (toggle fullscreen)
<prefix>z

# Kill pane
<prefix>x
```

### 4. Copy & Paste
```bash
# Enter copy mode
<prefix>[

# In copy mode:
v        # Start selection
y        # Copy selection
q        # Exit copy mode

# Paste
<prefix>]
```

## Advanced Configuration

### Status Line Customization
The Catppuccin theme provides a beautiful status line, but you can customize it:

```bash
# Add to tmux.conf for custom status line elements
set -g @catppuccin_window_left_separator ""
set -g @catppuccin_window_right_separator " "
set -g @catppuccin_window_middle_separator " █"
set -g @catppuccin_window_number_position "right"
```

### Plugin Configuration
Each plugin can be configured with additional options:

```bash
# Catppuccin theme options
set -g @catppuccin_flavour 'mocha' # or latte, frappe, macchiato

# tmux-yank options
set -g @yank_selection 'primary' # or 'secondary' or 'clipboard'
```

### Custom Key Bindings
Add your own keybindings to `tmux.conf`:

```bash
# Reload config
bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"

# Quick pane switching
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
```

## Integration with Neovim

### Seamless Navigation
The vim-tmux-navigator plugin allows you to navigate between Neovim splits and tmux panes using the same keys:

```bash
# Works in both Neovim and tmux
Ctrl+h  # Move left
Ctrl+j  # Move down
Ctrl+k  # Move up
Ctrl+l  # Move right
```

### Shared Clipboard
Both Neovim and tmux are configured to use the system clipboard, enabling:
- Copy in Neovim, paste in tmux
- Copy in tmux, paste in Neovim
- Copy in either, paste in external applications

## Troubleshooting

### Common Issues

1. **Colors not displaying correctly**
   ```bash
   # Check terminal capabilities
   echo $TERM
   
   # Should be screen-256color or tmux-256color
   # Set in your shell profile if needed
   export TERM=screen-256color
   ```

2. **Plugins not installing**
   ```bash
   # Manual plugin installation
   ~/.tmux/plugins/tpm/bin/install_plugins
   
   # Update plugins
   ~/.tmux/plugins/tpm/bin/update_plugins
   ```

3. **Navigation not working with Neovim**
   - Ensure vim-tmux-navigator is installed in both tmux and Neovim
   - Check that keybindings don't conflict
   - Verify Neovim has the corresponding plugin

4. **Copy to clipboard not working**
   - Install clipboard utilities:
     - macOS: Built-in (pbcopy/pbpaste)
     - Linux: `xclip` or `xsel`
   - Check tmux-yank plugin installation

### Useful Commands
```bash
# Check tmux version
tmux -V

# List all key bindings
tmux list-keys

# Show tmux info
tmux info

# Reload configuration
tmux source-file ~/.config/tmux/tmux.conf
```

## Performance Tips

1. **Escape Time**: Reduce delay for escape key
   ```bash
   set -sg escape-time 0
   ```

2. **History Limit**: Increase scrollback buffer
   ```bash
   set -g history-limit 10000
   ```

3. **Aggressive Resize**: Better window sizing
   ```bash
   setw -g aggressive-resize on
   ```

## Workflow Examples

### Development Workflow
```bash
# Start project session
tmux new -s myproject

# Create windows
<prefix>c           # New window for editor
<prefix>,           # Rename to "editor"
<prefix>c           # New window for server
<prefix>,           # Rename to "server"
<prefix>c           # New window for tests
<prefix>,           # Rename to "tests"

# In editor window
nvim               # Start Neovim
<prefix>"          # Split for terminal
```

### Multiple Projects
```bash
# List all sessions
tmux ls

# Switch between projects
<prefix>s          # Session selector

# Create new session without leaving current
<prefix>:new -s another-project -d
```

## Resources
- [Tmux Manual](https://man.openbsd.org/tmux)
- [TPM Documentation](https://github.com/tmux-plugins/tpm)
- [Catppuccin Theme](https://github.com/catppuccin/tmux)
- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)