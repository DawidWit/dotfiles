if vim.g.dotfiles_nvim_smoke then
  local explorer = require("plugins.explorer")
  local picker = require("plugins.picker")

  assert(type(explorer) == "table", "explorer spec did not load as a table")
  assert(type(picker) == "table", "picker spec did not load as a table")
  assert(vim.g.lazyvim_ts_lsp == "tsgo", "TypeScript LSP is not tsgo")

  local member_depth = require("config.member-depth")
  local highlight = member_depth.highlight
  local calls = 0
  member_depth.highlight = function(buf)
    calls = calls + 1
    return highlight(buf)
  end

  local lines = {}
  for line = 1, 5000 do
    lines[line] = "const value" .. line .. " = object.member.nested;"
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = "typescript"

  member_depth.schedule(vim.api.nvim_get_current_buf())
  assert(calls == 0, "highlight ran synchronously for the TypeScript sample")
  vim.wait(5000, function()
    return calls > 0
  end)
  assert(calls == 1, "expected one TypeScript highlight, got " .. calls)

  print("PASS: nvim-headless-smoke")
  return
end

local member_depth = require("config.member-depth")
local calls = 0
member_depth.highlight = function()
  calls = calls + 1
end

local buf = vim.api.nvim_get_current_buf()
member_depth.schedule(buf)
member_depth.schedule(buf)
member_depth.schedule(buf)

assert(calls == 0, "highlight ran synchronously")
vim.wait(300, function()
  return calls > 0
end)
assert(calls == 1, "expected one highlight, got " .. calls)

local other_buf = vim.api.nvim_create_buf(false, true)
member_depth.setup()

local calls_by_buf = {}
member_depth.highlight = function(target_buf)
  calls_by_buf[target_buf] = (calls_by_buf[target_buf] or 0) + 1
end

member_depth.schedule(buf)
member_depth.schedule(other_buf)
vim.api.nvim_exec_autocmds("BufWritePost", { buffer = buf })

assert(calls_by_buf[buf] == 1, "immediate refresh did not highlight exactly once")
assert(calls_by_buf[other_buf] == nil, "immediate refresh affected another buffer")
vim.wait(300, function()
  return calls_by_buf[other_buf] ~= nil
end)
assert(calls_by_buf[buf] == 1, "pending refresh duplicated immediate highlight")
assert(calls_by_buf[other_buf] == 1, "another buffer's pending refresh was superseded")

local deleted_buf = vim.api.nvim_create_buf(false, true)
member_depth.schedule(deleted_buf)
vim.api.nvim_buf_delete(deleted_buf, { force = true })
vim.wait(300)
assert(calls_by_buf[deleted_buf] == nil, "deleted buffer was highlighted")

print("PASS: member-depth-debounce")
