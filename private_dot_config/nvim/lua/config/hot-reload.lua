-- Re-applies config on save, without restarting nvim.
--
-- Only the parts that can be re-applied cleanly are hot-reloaded: highlight
-- colors and the member-depth module. Plugin specs, lazy.nvim's load order and
-- keymaps have side effects that can't be undone in a live process, so those
-- still need a restart — this says so rather than half-applying them.
local M = {}

local nvim_config = vim.fn.stdpath("config")
local palette_file = nvim_config .. "/lua/plugins/palette.lua"
local member_file = nvim_config .. "/lua/config/member-depth.lua"

-- palette.lua returns a lazy spec whose `on_highlights(hl)` assigns into a table
-- that tokyonight later applies. Handing it a proxy that writes straight through
-- to nvim_set_hl re-applies the colors with no theme reload.
local function reload_palette()
  local ok, spec = pcall(dofile, palette_file)
  if not ok then
    vim.notify("palette.lua: " .. tostring(spec), vim.log.levels.ERROR)
    return false
  end

  local on_highlights = vim.tbl_get(spec, "opts", "on_highlights")
  if type(on_highlights) ~= "function" then
    return false
  end

  local proxy = setmetatable({}, {
    __newindex = function(_, group, val)
      vim.api.nvim_set_hl(0, group, val)
    end,
  })
  on_highlights(proxy)
  return true
end

local function reload_member_depth()
  package.loaded["config.member-depth"] = nil
  local ok, mod = pcall(require, "config.member-depth")
  if not ok then
    vim.notify("member-depth.lua: " .. tostring(mod), vim.log.levels.ERROR)
    return false
  end
  mod.setup()
  return true
end

function M.setup()
  local group = vim.api.nvim_create_augroup("hot_reload", { clear = true })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = nvim_config .. "/lua/**/*.lua",
    callback = function(event)
      local file = vim.fs.normalize(event.match)

      if file == vim.fs.normalize(palette_file) then
        if reload_palette() then
          vim.notify("Palette reloaded", vim.log.levels.INFO, { title = "hot-reload" })
        end
      elseif file == vim.fs.normalize(member_file) then
        if reload_member_depth() then
          vim.notify("Member colors reloaded", vim.log.levels.INFO, { title = "hot-reload" })
        end
      else
        vim.notify(
          vim.fn.fnamemodify(file, ":t") .. " changed — restart nvim to apply",
          vim.log.levels.WARN,
          { title = "hot-reload" }
        )
      end
    end,
  })
end

return M
