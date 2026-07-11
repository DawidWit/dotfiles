-- File tree sidebar (snacks.explorer), rooted at the cwd nvim was launched from
-- rather than LazyVim's default of the detected project/git root.

---@param opts? snacks.picker.explorer.Config
local function explorer(opts)
  return Snacks.explorer(vim.tbl_extend("force", { cwd = vim.fn.getcwd() }, opts or {}))
end

-- Show the tree, or hide it if it's already the focused window.
local function toggle()
  local tree = Snacks.picker.get({ source = "explorer" })[1]
  if not tree then
    return explorer({ focus = "list" })
  elseif tree:is_focused() then
    return tree:close()
  end
  return tree:focus()
end

return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- show dotfiles
          ignored = false, -- but not what .gitignore excludes
          layout = { preset = "sidebar", preview = false },
          -- Badge files this branch committed vs its base branch, on top of
          -- the built-in working-tree status colors.
          format = require("config.explorer-git-branch").format,
        },
      },
    },
  },
  keys = {
    { "<leader>e", toggle, desc = "Explorer (toggle)" },
    -- Jump to the current file in the tree, opening it if needed.
    {
      "<leader>E",
      function()
        Snacks.explorer.reveal()
      end,
      desc = "Explorer (reveal file)",
    },
  },
}
