-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = wezterm.config_builder()

config.automatically_reload_config = true

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- colors
config.color_scheme = "nord"
config.window_background_opacity = 0.7
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"

-- font
config.font = wezterm.font("0xProto")
config.font_size = 14.0

-- keybind
config.disable_default_key_bindings = true
local keybinds = require("keybinds")
config.keys = keybinds.keys
config.key_tables = keybinds.key_tables

config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 1000 }

-- window
config.window_close_confirmation = "AlwaysPrompt"

-- moving tabs
for i = 1, 8 do
	-- CTRL+ALT + number to move to that position
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CTRL|ALT",
		action = wezterm.action.MoveTab(i - 1),
	})
end

-- show tab
config.show_tabs_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

-- enable to toggle bg blur
wezterm.on("toggle-blur", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if overrides.macos_window_background_blur == 0 then
		overrides.macos_window_background_blur = 20
	else
		overrides.macos_window_background_blur = 0
	end
	window:set_config_overrides(overrides)
end)

table.insert(config.keys, {
	key = "b",
	mods = "CMD|SHIFT",
	action = wezterm.action.EmitEvent("toggle-blur"),
})

-- and finally, return the configuration to wezterm
return config
