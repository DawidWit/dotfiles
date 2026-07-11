-- Colors member-expression chains by how deep each link sits:
--
--   console . log          →  root . field
--   foo     . bar . baz    →  root . field . nested
--
-- Neither treesitter nor the LSP encodes nesting depth — `log` in `console.log`
-- and `baz` in `foo.bar.baz` carry the identical capture — so depth has to be
-- walked off the syntax tree and painted as extmarks.
local M = {}

local colors = {
  root = "#ff757f", -- console, JSON, Math, and any object at the head of a chain
  field = "#d76997", -- .log, .stringify, .bar
  nested = "#a3659f", -- .baz and anything deeper
}

local groups = {
  root = "MemberRoot",
  field = "MemberField",
  nested = "MemberNested",
}

local ns = vim.api.nvim_create_namespace("member_depth")

local filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

-- LSP semantic tokens paint at priority 125; these have to sit above them or the
-- language server's own colors win.
local PRIORITY = 200

local function define_highlights()
  for key, group in pairs(groups) do
    vim.api.nvim_set_hl(0, group, { fg = colors[key] })
  end
end

-- How many member_expressions are nested inside this one's object chain.
-- `foo.bar` → 0, `foo.bar.baz` → 1, `foo.bar.baz.qux` → 2
local function chain_depth(node)
  local object = node:field("object")[1]
  if not object then
    return 0
  end
  if object:type() == "member_expression" then
    return 1 + chain_depth(object)
  end
  -- a().b keeps the chain going through the call
  if object:type() == "call_expression" then
    local fn = object:field("function")[1]
    if fn and fn:type() == "member_expression" then
      return 1 + chain_depth(fn)
    end
  end
  return 0
end

local function mark(buf, node, group)
  if not node then
    return
  end
  local row, col, end_row, end_col = node:range()
  vim.api.nvim_buf_set_extmark(buf, ns, row, col, {
    end_row = end_row,
    end_col = end_col,
    hl_group = group,
    priority = PRIORITY,
  })
end

function M.highlight(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) or not filetypes[vim.bo[buf].filetype] then
    return
  end

  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  local function walk(node)
    if node:type() == "member_expression" then
      local depth = 1 + chain_depth(node)
      mark(buf, node:field("property")[1], depth == 1 and groups.field or groups.nested)

      -- The head of the chain is the only object that isn't itself a member.
      local object = node:field("object")[1]
      if object and (object:type() == "identifier" or object:type() == "this") then
        mark(buf, object, groups.root)
      end
    end
    for child in node:iter_children() do
      if child:named() then
        walk(child)
      end
    end
  end

  walk(tree:root())
end

function M.setup()
  define_highlights()

  local group = vim.api.nvim_create_augroup("member_depth", { clear = true })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = define_highlights,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(event)
      M.highlight(event.buf)
    end,
  })

  -- Buffers already open when this loads (VeryLazy fires after the first BufEnter).
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      M.highlight(buf)
    end
  end
end

return M
