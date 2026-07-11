return {
  "folke/snacks.nvim",
  -- stylua: ignore
  keys = {
    -- Search lines in the current file. LazyVim puts this on <leader>sb.
    { "<leader>sb", false },
    { "<leader>sf", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
  },
}
