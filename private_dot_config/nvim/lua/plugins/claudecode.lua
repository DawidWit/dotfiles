return {
  "coder/claudecode.nvim",
  -- stylua: ignore
  keys = {
    -- Skips every permission prompt: Claude edits files and runs shell commands
    -- without asking. Plain `:ClaudeCode` still starts a session that prompts.
    { "<leader>ac", "<cmd>ClaudeCode --dangerously-skip-permissions<cr>", desc = "Toggle Claude (no prompts)" },
  },
}
