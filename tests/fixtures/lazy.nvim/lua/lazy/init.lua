local M = {}

function M.setup(options)
  assert(type(options) == "table", "lazy setup options must be a table")
  require("config.options")
  require("config.autocmds")
  require("config.keymaps")
end

return M
