local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.default_prog = { '/opt/homebrew/bin/tmux', 'new-session', '-A', '-s', 'main' }

-- ─── Font ────────────────────────────────────────────────────────────────────

config.font = wezterm.font_with_fallback {
  { family = 'JetBrains Mono', weight = 'Medium' },
  { family = 'Fira Code', weight = 'Medium' },
  'Noto Color Emoji',
}
config.font_size = 13.0
config.line_height = 1.15
config.harfbuzz_features = { 'calt', 'liga', 'dlig' }

-- ─── Color Scheme ────────────────────────────────────────────────────────────

config.color_scheme = 'Tokyo Night'

-- ─── Window ──────────────────────────────────────────────────────────────────

config.window_background_opacity = 0.95
config.window_padding = {
  left = 12,
  right = 12,
  top = 8,
  bottom = 4,
}
config.initial_cols = 140
config.initial_rows = 38
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'AlwaysPrompt'
config.adjust_window_size_when_changing_font_size = false

-- ─── Tab Bar ─────────────────────────────────────────────────────────────────

config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 32
config.show_tab_index_in_tab_bar = true

config.window_frame = {
  font = wezterm.font { family = 'JetBrains Mono', weight = 'Bold' },
  font_size = 11.0,
  active_titlebar_bg = '#1a1b26',
  inactive_titlebar_bg = '#16161e',
}

config.colors = {
  tab_bar = {
    inactive_tab_edge = '#24283b',
    active_tab = {
      bg_color = '#1a1b26',
      fg_color = '#c0caf5',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#16161e',
      fg_color = '#565f89',
    },
    inactive_tab_hover = {
      bg_color = '#24283b',
      fg_color = '#c0caf5',
      italic = true,
    },
    new_tab = {
      bg_color = '#16161e',
      fg_color = '#565f89',
    },
    new_tab_hover = {
      bg_color = '#24283b',
      fg_color = '#c0caf5',
    },
  },
}

-- ─── Status Bar ──────────────────────────────────────────────────────────────

wezterm.on('update-right-status', function(window, pane)
  local key_table = window:active_key_table()
  local workspace = window:active_workspace()
  local date = wezterm.strftime '%a %b %-d  %H:%M'

  local elements = {}

  if key_table then
    table.insert(elements, { Foreground = { Color = '#e0af68' } })
    table.insert(elements, { Text = ' ' .. key_table .. ' ' })
  end

  if workspace ~= 'default' then
    table.insert(elements, { Foreground = { Color = '#7aa2f7' } })
    table.insert(elements, { Text = ' ' .. workspace .. '  ' })
  end

  table.insert(elements, { Foreground = { Color = '#9ece6a' } })
  table.insert(elements, { Text = date .. '  ' })

  window:set_right_status(wezterm.format(elements))
end)

-- ─── Tab Title ───────────────────────────────────────────────────────────────

local function tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then
    return title
  end
  return tab_info.active_pane.title
end

wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local index = tab.tab_index + 1
  local title = tab_title(tab)

  if #title > max_width - 6 then
    title = title:sub(1, max_width - 9) .. '...'
  end

  if tab.is_active then
    return {
      { Attribute = { Intensity = 'Bold' } },
      { Text = ' ' .. index .. ': ' .. title .. ' ' },
    }
  end

  return ' ' .. index .. ': ' .. title .. ' '
end)

-- ─── Leader Key (tmux-style: CTRL+A) ────────────────────────────────────────

config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1500 }

-- ─── Keybindings ─────────────────────────────────────────────────────────────

config.keys = {
  -- Pass through CTRL+A by pressing it twice
  { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },

  -- Pane splits
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER',       action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Pane navigation (leader + vim keys)
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Pane navigation (CTRL+SHIFT + arrows, no leader needed)
  { key = 'LeftArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },

  -- Enter resize mode
  { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false } },

  -- Close pane
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

  -- Tabs
  { key = 'c', mods = 'LEADER',       action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER',       action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER',       action = act.ActivateTabRelative(-1) },
  { key = '&', mods = 'LEADER|SHIFT', action = act.CloseCurrentTab { confirm = true } },

  -- Tab selection by number (leader + 1-9)
  { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
  { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
  { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
  { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
  { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
  { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
  { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
  { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
  { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },

  -- Copy mode
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },

  -- Search
  { key = '/', mods = 'LEADER', action = act.Search 'CurrentSelectionOrEmptyString' },

  -- Quick select (URLs, hashes, etc.)
  { key = 'Space', mods = 'LEADER', action = act.QuickSelect },

  -- Font size
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },

  -- Toggle fullscreen
  { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },

  -- Zoom current pane
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

  -- Rotate panes
  { key = 'o', mods = 'LEADER', action = act.RotatePanes 'Clockwise' },

  -- Workspaces
  { key = 'w', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },

  -- Command palette
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

  -- Scrollback
  { key = 'UpArrow',   mods = 'CTRL', action = act.ScrollByLine(-1) },
  { key = 'DownArrow', mods = 'CTRL', action = act.ScrollByLine(1) },
  { key = 'PageUp',    mods = 'SHIFT', action = act.ScrollByPage(-1) },
  { key = 'PageDown',  mods = 'SHIFT', action = act.ScrollByPage(1) },
}

-- ─── Key Tables ──────────────────────────────────────────────────────────────

config.key_tables = {
  resize_pane = {
    { key = 'h',          action = act.AdjustPaneSize { 'Left', 2 } },
    { key = 'j',          action = act.AdjustPaneSize { 'Down', 2 } },
    { key = 'k',          action = act.AdjustPaneSize { 'Up', 2 } },
    { key = 'l',          action = act.AdjustPaneSize { 'Right', 2 } },
    { key = 'LeftArrow',  action = act.AdjustPaneSize { 'Left', 2 } },
    { key = 'DownArrow',  action = act.AdjustPaneSize { 'Down', 2 } },
    { key = 'UpArrow',    action = act.AdjustPaneSize { 'Up', 2 } },
    { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 2 } },
    { key = 'Escape',     action = 'PopKeyTable' },
    { key = 'Enter',      action = 'PopKeyTable' },
  },
}

-- ─── Scrollback ──────────────────────────────────────────────────────────────

config.scrollback_lines = 10000

-- ─── Cursor ──────────────────────────────────────────────────────────────────

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- ─── Misc ────────────────────────────────────────────────────────────────────

config.check_for_updates = false
config.automatically_reload_config = true
config.audible_bell = 'Disabled'
config.max_fps = 120
config.animation_fps = 60
config.enable_scroll_bar = true
config.enable_wayland = true
config.front_end = 'WebGpu'

return config
