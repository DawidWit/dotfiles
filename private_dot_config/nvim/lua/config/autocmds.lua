-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

require("config.member-depth").setup()
require("config.hot-reload").setup()

-- :Tutor marks exercise lines with two same-priority extmarks: the ✓/✗ sign
-- and a line highlight. Snacks' statuscolumn keeps only the highest-priority
-- sign per line, and on that tie the highlight-only one (no sign text) can
-- win, so the marks render blank. Fall back to the native sign column here.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("tutor_native_signcolumn", { clear = true }),
  pattern = "tutor",
  callback = function()
    vim.opt_local.statuscolumn = ""
  end,
})
