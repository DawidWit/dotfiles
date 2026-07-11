-- Marks files this branch has committed relative to its base branch as a
-- trailing badge in the snacks.nvim explorer, layered on top of the built-in
-- working-tree status colors. "Committed on this branch" is the three-dot
-- `git diff base...HEAD` (merge-base), so it excludes uncommitted changes.
--
-- The base branch is auto-detected per repo (origin/HEAD, then common
-- fallbacks); :ExplorerBranchBase overrides it for the current repo.

local M = {}

local HL = "SnacksExplorerBranchChanged"
local BADGE = "●"
local TTL = 30
local FALLBACK_BASES = { "origin/main", "origin/master", "main", "master", "develop", "test" }

M.cache = {} ---@type table<string, { files: table<string, boolean>, base?: string, last: number, running: boolean }>
M.override = {} ---@type table<string, string>

local root_by_cwd = {}
local function root_of(cwd)
  if cwd == nil then
    return nil
  end
  if root_by_cwd[cwd] == nil then
    root_by_cwd[cwd] = Snacks.git.get_root(cwd) or false
  end
  return root_by_cwd[cwd] or nil
end

local function refresh()
  local ok, pickers = pcall(Snacks.picker.get, { source = "explorer" })
  if not ok then
    return
  end
  for _, picker in ipairs(pickers) do
    if not picker.closed then
      picker.list:set_target()
      picker:find({})
    end
  end
end

-- Resolve the base ref for `root`, then call `cb(base|nil)`.
local function resolve_base(root, cb)
  if M.override[root] then
    return cb(M.override[root])
  end
  vim.system({ "git", "-C", root, "rev-parse", "--abbrev-ref", "origin/HEAD" }, { text = true }, function(res)
    local detected = vim.trim(res.stdout or "")
    if res.code == 0 and detected ~= "" and detected ~= "origin/HEAD" then
      return cb(detected)
    end
    local index = 0
    local function probe()
      index = index + 1
      local candidate = FALLBACK_BASES[index]
      if not candidate then
        return cb(nil)
      end
      vim.system({ "git", "-C", root, "rev-parse", "--verify", "--quiet", candidate .. "^{commit}" }, {}, function(r)
        if r.code == 0 then
          cb(candidate)
        else
          probe()
        end
      end)
    end
    probe()
  end)
end

function M.compute(root)
  local entry = M.cache[root]
  if entry and entry.running then
    return
  end
  if entry and os.time() - entry.last < TTL then
    return
  end
  M.cache[root] = entry or { files = {}, last = 0, running = false }
  M.cache[root].running = true

  resolve_base(root, function(base)
    local function done(files)
      M.cache[root] = { files = files, base = base, last = os.time(), running = false }
      vim.schedule(refresh)
    end
    if not base then
      return done({})
    end
    vim.system(
      { "git", "-C", root, "diff", "--name-only", "--no-color", "-z", base .. "...HEAD" },
      { text = true },
      function(res)
        local files = {}
        if res.code == 0 and res.stdout then
          for _, rel in ipairs(vim.split(res.stdout, "\0", { plain = true })) do
            if rel ~= "" then
              local abs = vim.fs.normalize(root .. "/" .. rel)
              files[abs] = true
              for dir in Snacks.picker.util.parents(abs, root) do
                files[dir] = true
              end
            end
          end
        end
        done(files)
      end
    )
  end)
end

function M.format(item, picker)
  local ret = Snacks.picker.format.file(item, picker)
  local root = item.file and root_of(picker:cwd())
  if root then
    M.compute(root)
    local entry = M.cache[root]
    if entry and entry.files[vim.fs.normalize(item.file)] then
      ret[#ret + 1] = { " ", virtual = true }
      ret[#ret + 1] = { BADGE, HL, virtual = true }
    end
  end
  return ret
end

function M.setup()
  local group = vim.api.nvim_create_augroup("explorer_branch_colors", { clear = true })

  local function set_hl()
    vim.api.nvim_set_hl(0, HL, { fg = "#bb9af7", default = true })
  end
  set_hl()
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })

  -- A commit/checkout in another pane fires no nvim event, so re-check on focus.
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      for _, entry in pairs(M.cache) do
        entry.last = 0
      end
      local ok, pickers = pcall(Snacks.picker.get, { source = "explorer" })
      if not ok then
        return
      end
      for _, picker in ipairs(pickers) do
        local root = not picker.closed and root_of(picker:cwd())
        if root then
          M.compute(root)
        end
      end
    end,
  })

  vim.api.nvim_create_user_command("ExplorerBranchBase", function(cmd)
    local root = Snacks.git.get_root(vim.fn.getcwd())
    if not root then
      return vim.notify("Not inside a git repository", vim.log.levels.WARN)
    end
    local ref = vim.trim(cmd.args)
    M.override[root] = ref ~= "" and ref or nil
    local entry = M.cache[root]
    if entry then
      entry.last = 0
    end
    M.compute(root)
    vim.notify("Explorer branch base: " .. (M.override[root] or "auto"), vim.log.levels.INFO)
  end, {
    nargs = "?",
    desc = "Set/reset the base branch for explorer branch-diff coloring",
    complete = function()
      local root = Snacks.git.get_root(vim.fn.getcwd())
      if not root then
        return {}
      end
      local res = vim
        .system(
          { "git", "-C", root, "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes" },
          { text = true }
        )
        :wait()
      return vim.split(vim.trim(res.stdout or ""), "\n", { plain = true })
    end,
  })
end

M.setup()

return M
