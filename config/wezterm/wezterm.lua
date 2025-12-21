-- WezTerm: Selenized Dark + Unified ALT keybindings
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- Selenized Dark (ANSI 16)
-- https://github.com/jan-warchol/selenized
--------------------------------------------------------------------------------
config.colors = {
  foreground = '#adbcbc',
  background = '#1c1c1c',

  cursor_bg = '#41c7b9',
  cursor_fg = '#103c48',
  cursor_border = '#41c7b9',

  selection_fg = '#103c48',
  selection_bg = '#adbcbc',

  ansi = {
    '#184956', -- black
    '#fa5750', -- red
    '#41c7b9', -- green (using cyan for easier reading)
    '#dbb32d', -- yellow
    '#4695f7', -- blue
    '#f275be', -- magenta
    '#41c7b9', -- cyan
    '#adbcbc', -- white
  },
  brights = {
    '#2d5b69', -- bright black
    '#ff665c', -- bright red
    '#84c747', -- bright green
    '#ebc13d', -- bright yellow
    '#58a3ff', -- bright blue
    '#ff84cd', -- bright magenta
    '#53d6c7', -- bright cyan
    '#cad8d9', -- bright white
  },

  tab_bar = {
    background = '#141414',
    active_tab = { bg_color = '#1c1c1c', fg_color = '#adbcbc' },
    inactive_tab = { bg_color = '#141414', fg_color = '#72898f' },
    inactive_tab_hover = { bg_color = '#2a2a2a', fg_color = '#adbcbc' },
    new_tab = { bg_color = '#141414', fg_color = '#72898f' },
    new_tab_hover = { bg_color = '#2a2a2a', fg_color = '#adbcbc' },
  },
}

--------------------------------------------------------------------------------
-- Font & Appearance
--------------------------------------------------------------------------------
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 12.0
config.line_height = 1.2

config.window_decorations = 'NONE'
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.show_tab_index_in_tab_bar = true
config.window_close_confirmation = 'NeverPrompt'

-- Tab bar font size
config.window_frame = {
  font = wezterm.font('JetBrainsMono Nerd Font'),
  font_size = 24.0,
}

config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_background_opacity = 0.9

--------------------------------------------------------------------------------
-- Terminal Behavior
--------------------------------------------------------------------------------
config.default_cursor_style = 'SteadyBlock'
config.audible_bell = 'Disabled'
config.scrollback_lines = 10000

config.skip_close_confirmation_for_processes_named = {
  'bash', 'sh', 'zsh', 'fish', 'tmux', 'vim', 'yazi'
}

-- Wayland / GPU
config.enable_wayland = true
config.front_end = 'OpenGL'

-- Let ALT pass through for keybindings (not compose characters)
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

--------------------------------------------------------------------------------
-- Keybindings: Unified ALT scheme
-- ALT + hjkl = navigate (matches vim)
-- ALT + d/D  = split
-- ALT + w    = close pane
-- ALT + t    = new tab
-- CTRL+SHIFT = copy/paste (Linux standard)
--------------------------------------------------------------------------------
config.keys = {
  -- Pane navigation (ALT + hjkl)
  { key = 'h', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' },

  -- Pane splits
  { key = 'd', mods = 'ALT', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'ALT|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Close pane
  { key = 'w', mods = 'ALT', action = wezterm.action.CloseCurrentPane { confirm = false } },

  -- Pane resize (ALT + CTRL + hjkl)
  { key = 'h', mods = 'ALT|CTRL', action = wezterm.action.AdjustPaneSize { 'Left', 3 } },
  { key = 'j', mods = 'ALT|CTRL', action = wezterm.action.AdjustPaneSize { 'Down', 3 } },
  { key = 'k', mods = 'ALT|CTRL', action = wezterm.action.AdjustPaneSize { 'Up', 3 } },
  { key = 'l', mods = 'ALT|CTRL', action = wezterm.action.AdjustPaneSize { 'Right', 3 } },

  -- Tab management
  { key = 't', mods = 'ALT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'ALT|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = false } },
  { key = '1', mods = 'ALT', action = wezterm.action.ActivateTab(0) },
  { key = '2', mods = 'ALT', action = wezterm.action.ActivateTab(1) },
  { key = '3', mods = 'ALT', action = wezterm.action.ActivateTab(2) },
  { key = '4', mods = 'ALT', action = wezterm.action.ActivateTab(3) },
  { key = '5', mods = 'ALT', action = wezterm.action.ActivateTab(4) },
  { key = '[', mods = 'ALT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = ']', mods = 'ALT', action = wezterm.action.ActivateTabRelative(1) },

  -- Copy/paste (Linux standard)
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },

  -- Utilities
  { key = 'f', mods = 'ALT', action = wezterm.action.Search 'CurrentSelectionOrEmptyString' },
  { key = 'z', mods = 'ALT', action = wezterm.action.TogglePaneZoomState },
  { key = ' ', mods = 'ALT', action = wezterm.action.ActivateCopyMode },
}

--------------------------------------------------------------------------------
-- Mouse
--------------------------------------------------------------------------------
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = 'Left' } }, mods = 'CTRL', action = wezterm.action.OpenLinkAtMouseCursor },
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = wezterm.action.PasteFrom 'Clipboard' },
}

--------------------------------------------------------------------------------
-- SSH Domains (homelab)
-- Configure your own hosts in ~/.ssh/config then reference here
-- Example: { name = 'server', remote_address = 'server.local', username = 'user' }
--------------------------------------------------------------------------------
config.ssh_domains = {
  -- Uncomment and customize for your homelab:
  -- { name = 'laptop',   remote_address = 'laptop.local',   username = 'user' },
  -- { name = 'hypervisor', remote_address = 'hypervisor.local', username = 'user' },
  -- { name = 'compute',  remote_address = 'compute.local',  username = 'user' },
  -- { name = 'storage',  remote_address = 'storage.local',  username = 'user' },
}

return config
