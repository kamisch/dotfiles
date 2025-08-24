require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", 'pyright', 'ruff', 'hadolint', 'gdscript'}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for hanging options of lsp servers 
