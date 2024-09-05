local wezterm = require("wezterm")

local config = wezterm.config_builder()

function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Macchiato"
	else
		return "Catppuccin Latte"
	end
end

function set_stream_mode(mode) end

wezterm.on("user-var-changed", function(window, pane, name, value)
	local overrides = window:get_config_overrides() or {}
	if name == "ZEN_MODE" then
		local incremental = value:find("+")
		local number_value = tonumber(value)
		if incremental ~= nil then
			while number_value > 0 do
				window:perform_action(wezterm.action.IncreaseFontSize, pane)
				number_value = number_value - 1
			end
			overrides.enable_tab_bar = false
		elseif number_value < 0 then
			window:perform_action(wezterm.action.ResetFontSize, pane)
			overrides.font_size = nil
			overrides.enable_tab_bar = true
		else
			overrides.font_size = number_value
			overrides.enable_tab_bar = false
		end
	end
	window:set_config_overrides(overrides)
end)

config = {
	automatically_reload_config = true,
	color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
	enable_tab_bar = false,
	font_size = 19,
	font = wezterm.font("Mononoki Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE",
	window_background_opacity = 0.9,
	text_background_opacity = 0.9,
}

return config
