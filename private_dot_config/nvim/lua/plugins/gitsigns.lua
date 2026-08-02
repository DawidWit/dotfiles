-- GitLens-style inline blame: virtual text at the end of the cursor line
-- showing who last touched it. Everything else about gitsigns is LazyVim's
-- default (gutter signs, ]h/[h navigation, <leader>gh* hunk actions).

return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 300,
      ignore_whitespace = true,
    },
    current_line_blame_formatter = "  <author>, <author_time:%R> · <summary>",
    current_line_blame_formatter_nc = "", -- stay quiet on uncommitted lines
  },
  keys = {
    {
      "<leader>uB",
      "<cmd>Gitsigns toggle_current_line_blame<cr>",
      desc = "Toggle Inline Blame",
    },
  },
}
