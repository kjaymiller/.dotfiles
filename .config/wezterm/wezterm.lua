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

config = {
	automatically_reload_config = true,
	color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
	enable_tab_bar = false,
	font_size = 19,
	font = wezterm.font("Mononoki Nerd Font", { weight = "Regular", stretch = "Normal", style = "Normal" }),
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE",
	window_background_opacity = 0.8,
	text_background_opacity = 0.8,
}

return config
