require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", 'pyright', 'ruff', 'hadolint', 'gdscript', 'clangd'}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for hanging options of lsp servers 
