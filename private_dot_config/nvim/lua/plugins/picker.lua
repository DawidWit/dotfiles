local function findFilesMatchingSearch(options, context)
  local filesContext = context:clone(options)
  filesContext.filter = context.filter:clone()

  local search = filesContext.filter.search
  filesContext.filter.search = search == "" and "" or ("*" .. search .. "*")

  return require("snacks.picker.source.files").files(options, filesContext)
end

local function searchEverything()
  Snacks.picker.pick({
    cwd = LazyVim.root(),
    live = true,
    multi = {
      { source = "files", finder = findFilesMatchingSearch },
      { source = "grep", regex = false },
    },
    title = "Search Everything",
  })
end

return {
  "folke/snacks.nvim",
  -- stylua: ignore
  keys = {
    -- Search lines in the current file. LazyVim puts this on <leader>sb.
    { "<leader>sb", false },
    { "<leader>se", searchEverything, desc = "Search Everything" },
    { "<leader>sf", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
  },
}
