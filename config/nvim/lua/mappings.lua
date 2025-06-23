require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Add the vim-tmux-navigator keymaps here
-- These map Ctrl-h, Ctrl-l, Ctrl-j, Ctrl-k, and Ctrl-\
-- to the respective TmuxNavigator commands.
map("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>", { desc = "Tmux window left" })
map("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>", { desc = "Tmux window right" })
map("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>", { desc = "Tmux window down" })
map("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>", { desc = "Tmux window up" })
map("n", "<C-\\>", "<cmd> TmuxNavigatePrevious<CR>", { desc = "Tmux previous window" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
