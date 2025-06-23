# NvChad Configuration Guide

## Overview
NvChad is a Neovim configuration framework that provides a beautiful, fast, and extensible setup. Your configuration uses NvChad v2.5 with additional customizations.

## Configuration Structure

```
~/.config/nvim/
├── init.lua                 # Main entry point
├── lua/
│   ├── chadrc.lua          # NvChad configuration
│   ├── options.lua         # Neovim options
│   ├── autocmds.lua        # Auto commands
│   ├── mappings.lua        # Key mappings
│   ├── configs/            # Plugin configurations
│   │   ├── conform.lua     # Code formatting
│   │   ├── lazy.lua        # Plugin manager config
│   │   └── lspconfig.lua   # LSP configuration
│   └── plugins/            # Plugin specifications
│       ├── init.lua        # Main plugins
│       ├── tmux.lua        # Tmux integration
│       └── anyname.lua     # Custom plugins
└── lazy-lock.json          # Plugin version lock
```

## Key Features Enabled

### Theme & UI
- **Theme**: Catppuccin (configured in `chadrc.lua`)
- **Color column**: Set at 120 characters
- **Relative line numbers**: Enabled
- **Base46**: NvChad's theming system

### Plugin Manager
- **Lazy.nvim**: Modern plugin manager
- **Lazy loading**: Plugins load only when needed
- **Lock file**: Ensures consistent plugin versions

### LSP (Language Server Protocol)
- **nvim-lspconfig**: LSP configuration
- **Automatic setup**: LSP servers configured per project
- **Diagnostics**: Error/warning display
- **Code actions**: Available via `<Space>ca`

### Code Formatting
- **conform.nvim**: Code formatting
- **Multiple formatters**: Support for various languages
- **Format on save**: Can be enabled (commented out by default)

### Tmux Integration
- **vim-tmux-navigator**: Seamless navigation between nvim and tmux
- **Consistent keybindings**: Same keys work in both environments

## Custom Configurations

### Key Mappings (`mappings.lua`)
```lua
-- Custom mappings added to NvChad defaults
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Tmux navigation
map("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>")
map("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>")
map("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>")
map("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>")
map("n", "<C-\\>", "<cmd> TmuxNavigatePrevious<CR>")
```

### Options (`options.lua`)
- Custom Neovim settings
- Overrides NvChad defaults where needed

### Theme Configuration (`chadrc.lua`)
```lua
M.base46 = {
    theme = "catppuccin",
    -- Additional theme customizations can be added here
}
```

## Plugin Management

### Installing New Plugins
1. Add plugin specification to `lua/plugins/init.lua` or create new file in `lua/plugins/`
2. Restart Neovim
3. Lazy.nvim will automatically install new plugins

### Example Plugin Addition
```lua
-- In lua/plugins/init.lua or new file
return {
  {
    "plugin-author/plugin-name",
    config = function()
      -- Plugin configuration
    end,
  },
}
```

### Managing Plugin Updates
- `:Lazy` - Open Lazy.nvim dashboard
- `:Lazy update` - Update all plugins
- `:Lazy clean` - Remove unused plugins
- `:Lazy sync` - Update and clean

## Language Server Setup

### Adding New LSP Servers
1. Edit `lua/configs/lspconfig.lua`
2. Add server configuration:
```lua
lspconfig.your_lsp_server.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  -- Additional server-specific config
}
```

### Available LSP Commands
- `gd` - Go to definition
- `gr` - Go to references  
- `K` - Hover documentation
- `<Space>ca` - Code actions
- `<Space>rn` - Rename symbol
- `]d` / `[d` - Next/previous diagnostic

## Code Formatting

### Supported Formatters (conform.nvim)
- Configure in `lua/configs/conform.lua`
- Add formatters per filetype
- Enable format on save if desired

### Example Formatter Configuration
```lua
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "black" },
    javascript = { "prettier" },
  },
})
```

## Customization Tips

### 1. Adding Custom Keymaps
Add to `lua/mappings.lua`:
```lua
local map = vim.keymap.set

map("n", "<leader>my", "<cmd>MyCommand<CR>", { desc = "My custom command" })
```

### 2. Custom Auto Commands
Add to `lua/autocmds.lua`:
```lua
local autocmd = vim.api.nvim_create_autocmd

autocmd("BufWritePre", {
  pattern = "*.lua",
  callback = function()
    -- Custom action before saving Lua files
  end,
})
```

### 3. Plugin-Specific Settings
Create new files in `lua/configs/` for plugin configurations:
```lua
-- lua/configs/my-plugin.lua
local M = {}

M.setup = function()
  require("my-plugin").setup({
    -- Plugin configuration
  })
end

return M
```

## Troubleshooting

### Common Issues

1. **Plugin not loading**
   - Check `:Lazy` for plugin status
   - Verify plugin specification syntax
   - Check for conflicts in `lazy-lock.json`

2. **LSP not working**
   - Install language server: `:LspInstall server_name`
   - Check `:LspInfo` for server status
   - Verify server configuration in `lspconfig.lua`

3. **Keybindings not working**
   - Check for conflicts: `:map <key>`
   - Verify mapping syntax in `mappings.lua`
   - Ensure plugin dependencies are loaded

4. **Theme issues**
   - Clear cache: `rm -rf ~/.local/share/nvim/base46/`
   - Restart Neovim
   - Check theme name in `chadrc.lua`

### Useful Commands
- `:checkhealth` - Check Neovim health
- `:NvChadUpdate` - Update NvChad
- `:Lazy profile` - Plugin loading performance
- `:Mason` - Manage LSP servers, formatters, linters

## Advanced Configuration

### Custom Highlights
```lua
-- In chadrc.lua
M.base46 = {
  theme = "catppuccin",
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}
```

### Custom NvChad Modules
```lua
-- Enable/disable NvChad features
M.ui = {
  tabufline = {
    lazyload = false
  }
}

M.nvdash = { 
  load_on_startup = true 
}
```

## Backup & Recovery
- Configuration files are version controlled
- `lazy-lock.json` ensures plugin version consistency
- Back up before major changes:
  ```bash
  cp -r ~/.config/nvim ~/.config/nvim.backup
  ```

## Resources
- [NvChad Documentation](https://nvchad.com/)
- [Lazy.nvim Documentation](https://github.com/folke/lazy.nvim)
- [Base46 Themes](https://github.com/NvChad/base46)
- [Plugin Examples](https://github.com/NvChad/NvChad/tree/v2.5/lua/nvchad/plugins)