-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+click to go to definition, like VSCode. <LeftMouse> runs first so the
-- cursor lands on what was clicked, then jumps. This replaces nvim's default
-- binding of <C-LeftMouse> to the old ctags jump.
-- The keyboard equivalent is `gd`, which LazyVim already binds to the same thing.
vim.keymap.set("n", "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<cr>", { desc = "Go to definition" })

-- Smooth viewport scrolling: holding Shift+Up/Down repeats these small
-- movements, while Snacks animates each viewport change.
vim.keymap.set("n", "<S-Up>", "3<C-Y>", { desc = "Scroll up smoothly" })
vim.keymap.set("n", "<S-Down>", "3<C-E>", { desc = "Scroll down smoothly" })
