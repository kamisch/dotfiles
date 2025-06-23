# Developer Cheatsheet

## Neovim (NvChad) - Essential Commands

### File Operations
- `<Space>ff` - Find files (telescope)
- `<Space>fa` - Find all files (including hidden)
- `<Space>fw` - Find word (grep search)
- `<Space>fb` - Find buffers
- `<Space>fh` - Find help
- `<Space>fo` - Find old files
- `<Space>fz` - Find in current buffer
- `<Space>e` - Toggle file explorer (NvimTree)
- `<Ctrl>n` - Toggle file explorer
- `<Ctrl>s` - Save file

### Window/Buffer Management
- `<Space>x` - Close buffer
- `<Tab>` - Next buffer
- `<Shift><Tab>` - Previous buffer
- `<Space>h` - New horizontal split
- `<Space>v` - New vertical split

### Navigation (with tmux integration)
- `<Ctrl>h` - Move to left pane/window
- `<Ctrl>j` - Move to lower pane/window  
- `<Ctrl>k` - Move to upper pane/window
- `<Ctrl>l` - Move to right pane/window
- `<Ctrl>\` - Move to previous pane/window

### Code Features
- `gd` - Go to definition
- `gr` - Go to references
- `K` - Hover documentation
- `<Space>ca` - Code actions
- `<Space>rn` - Rename symbol
- `<Space>f` - Format code
- `]d` / `[d` - Next/previous diagnostic
- `<Space>q` - Show diagnostics

### Search & Replace
- `/` - Search forward
- `?` - Search backward
- `n` / `N` - Next/previous search result
- `<Space>s` - Search and replace in current buffer

### Custom Mappings
- `;` - Enter command mode (instead of `:`)
- `jk` - Exit insert mode (instead of `<Esc>`)

## Tmux - Essential Commands

### Sessions
- `tmux` - Start new session
- `tmux new -s <name>` - Start named session
- `tmux ls` - List sessions
- `tmux attach -t <name>` - Attach to session
- `tmux kill-session -t <name>` - Kill session

### Inside tmux (prefix = `Ctrl+Space`)
#### Session Management
- `<prefix>d` - Detach from session
- `<prefix>s` - Switch sessions
- `<prefix>$` - Rename session

#### Window Management
- `<prefix>c` - Create new window
- `<prefix>,` - Rename window
- `<prefix>n` - Next window
- `<prefix>p` - Previous window
- `<prefix>0-9` - Switch to window by number
- `<prefix>&` - Kill window

#### Pane Management
- `<prefix>"` - Split horizontally (new pane below)
- `<prefix>%` - Split vertically (new pane right)
- `<prefix>x` - Kill pane
- `<prefix>z` - Zoom/unzoom pane
- `<prefix>{` - Move pane left
- `<prefix>}` - Move pane right
- `<prefix>q` - Show pane numbers

#### Navigation (vim-tmux-navigator)
- `<Ctrl>h` - Move left (works between nvim and tmux)
- `<Ctrl>j` - Move down
- `<Ctrl>k` - Move up
- `<Ctrl>l` - Move right

#### Copy Mode (vi-mode enabled)
- `<prefix>[` - Enter copy mode
- `v` - Start selection
- `y` - Copy selection
- `<prefix>]` - Paste

#### Plugin Management
- `<prefix>I` - Install plugins
- `<prefix>U` - Update plugins
- `<prefix>alt+u` - Remove unused plugins

## Git Integration

### Neovim Git Commands
- `<Space>gi` - Git status
- `<Space>gc` - Git commits
- `<Space>gt` - Git stash
- `<Space>gb` - Git branches

## Common Workflows

### 1. Starting a Development Session
```bash
# Start named tmux session
tmux new -s project-name

# Create windows for different purposes
<prefix>c  # New window
<prefix>,  # Rename to "editor"

<prefix>c  # Another window  
<prefix>,  # Rename to "server"

# In editor window, split for terminal
<prefix>"  # Horizontal split
nvim       # Start nvim in top pane
```

### 2. File Navigation & Editing
```
# In nvim
<Space>ff  # Find and open file
<Space>e   # Toggle file tree
<Space>fw  # Search for text in files
```

### 3. Managing Multiple Projects
```bash
# List all sessions
tmux ls

# Switch between sessions
<prefix>s

# Create new session without detaching
tmux new -d -s another-project
```

### 4. Restoring Session
```bash
# Attach to existing session
tmux attach -t project-name

# Or if only one session
tmux attach
```

## Useful Tips

1. **Tmux Copy to System Clipboard**: Copy mode with `y` automatically copies to system clipboard (tmux-yank plugin)

2. **Neovim Terminal**: Use `:terminal` or `<Space>h` / `<Space>v` for integrated terminal

3. **Session Persistence**: Consider using tmux-resurrect plugin for session persistence across reboots

4. **Quick Config Edit**: 
   - Nvim config: `nvim ~/.config/nvim/init.lua`
   - Tmux config: `nvim ~/.config/tmux/tmux.conf`

5. **Reload Configs**:
   - Tmux: `<prefix>r` or `tmux source ~/.config/tmux/tmux.conf`
   - Nvim: `:source %` or restart nvim