-- Drop LazyVim's clock from the statusline. The tmux status bar already shows
-- the date and time, so repeating it here is just noise.

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_z = {}
  end,
}
