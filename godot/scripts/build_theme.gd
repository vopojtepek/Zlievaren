extends SceneTree

func _init() -> void:
	print("Generating theme...")
	var theme = Theme.new()
	
	# Load fonts
	var font_body: Font = load("res://assets/fonts/DMSans.ttf")
	var font_bold: Font = load("res://assets/fonts/BarlowCondensed-Bold.ttf")
	var font_semi: Font = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	
	theme.default_font = font_body
	theme.default_font_size = 14
	
	# Web palette colors
	var col_bg = Color("#101b22")
	var col_panel = Color("#192b32")
	var col_border = Color("#304750")
	var col_accent = Color("#ffa75f")
	var col_accent_hover = Color("#ffb87d")
	var col_text = Color("#e8f0ed")
	var col_muted = Color("#8fa89b")
	var col_success = Color("#b4d7b5")
	var col_danger = Color("#e76f51")
	
	# PanelContainer / Panel
	var sb_panel = StyleBoxFlat.new()
	sb_panel.bg_color = col_panel
	sb_panel.border_color = col_border
	sb_panel.set_border_width_all(1)
	sb_panel.set_corner_radius_all(6)
	sb_panel.set_content_margin_all(8)
	theme.set_stylebox("panel", "PanelContainer", sb_panel)
	theme.set_stylebox("panel", "Panel", sb_panel)
	
	# Buttons
	var sb_btn_normal = StyleBoxFlat.new()
	sb_btn_normal.bg_color = Color("#1c333d")
	sb_btn_normal.border_color = col_border
	sb_btn_normal.set_border_width_all(1)
	sb_btn_normal.set_corner_radius_all(4)
	sb_btn_normal.set_content_margin_all(6)
	
	var sb_btn_hover = StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color("#24424e")
	sb_btn_hover.border_color = col_accent
	sb_btn_hover.set_border_width_all(1)
	sb_btn_hover.set_corner_radius_all(4)
	sb_btn_hover.set_content_margin_all(6)
	
	var sb_btn_pressed = StyleBoxFlat.new()
	sb_btn_pressed.bg_color = col_accent
	sb_btn_pressed.border_color = col_accent_hover
	sb_btn_pressed.set_border_width_all(1)
	sb_btn_pressed.set_corner_radius_all(4)
	sb_btn_pressed.set_content_margin_all(6)
	
	var sb_btn_disabled = StyleBoxFlat.new()
	sb_btn_disabled.bg_color = Color("#121f25")
	sb_btn_disabled.border_color = Color("#1e2f37")
	sb_btn_disabled.set_border_width_all(1)
	sb_btn_disabled.set_corner_radius_all(4)
	sb_btn_disabled.set_content_margin_all(6)
	
	theme.set_stylebox("normal", "Button", sb_btn_normal)
	theme.set_stylebox("hover", "Button", sb_btn_hover)
	theme.set_stylebox("pressed", "Button", sb_btn_pressed)
	theme.set_stylebox("disabled", "Button", sb_btn_disabled)
	theme.set_stylebox("focus", "Button", sb_btn_hover)
	
	theme.set_font("font", "Button", font_semi)
	theme.set_font_size("font_size", "Button", 15)
	theme.set_color("font_color", "Button", col_text)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color("#101b22"))
	theme.set_color("font_disabled_color", "Button", Color("#556b73"))
	
	# Label
	theme.set_color("font_color", "Label", col_text)
	
	# ProgressBar
	var sb_prog_bg = StyleBoxFlat.new()
	sb_prog_bg.bg_color = Color("#0b1419")
	sb_prog_bg.border_color = col_border
	sb_prog_bg.set_border_width_all(1)
	sb_prog_bg.set_corner_radius_all(3)
	
	var sb_prog_fg = StyleBoxFlat.new()
	sb_prog_fg.bg_color = col_accent
	sb_prog_fg.set_corner_radius_all(3)
	
	theme.set_stylebox("background", "ProgressBar", sb_prog_bg)
	theme.set_stylebox("fill", "ProgressBar", sb_prog_fg)
	theme.set_font("font", "ProgressBar", font_semi)
	theme.set_font_size("font_size", "ProgressBar", 12)
	theme.set_color("font_color", "ProgressBar", Color.WHITE)
	
	# LineEdit
	var sb_input = StyleBoxFlat.new()
	sb_input.bg_color = Color("#0e171c")
	sb_input.border_color = col_border
	sb_input.set_border_width_all(1)
	sb_input.set_corner_radius_all(4)
	sb_input.set_content_margin_all(6)
	theme.set_stylebox("normal", "LineEdit", sb_input)
	theme.set_stylebox("focus", "LineEdit", sb_btn_hover)
	theme.set_color("font_color", "LineEdit", col_text)
	
	# TabBar / TabContainer
	var sb_tab_selected = StyleBoxFlat.new()
	sb_tab_selected.bg_color = col_panel
	sb_tab_selected.border_color = col_accent
	sb_tab_selected.border_width_bottom = 2
	sb_tab_selected.set_content_margin_all(8)
	
	var sb_tab_unselected = StyleBoxFlat.new()
	sb_tab_unselected.bg_color = col_bg
	sb_tab_unselected.set_content_margin_all(8)
	
	theme.set_stylebox("tab_selected", "TabBar", sb_tab_selected)
	theme.set_stylebox("tab_unselected", "TabBar", sb_tab_unselected)
	theme.set_stylebox("tab_hovered", "TabBar", sb_tab_selected)
	theme.set_font("font", "TabBar", font_bold)
	theme.set_font_size("font_size", "TabBar", 15)
	theme.set_color("font_selected_color", "TabBar", col_accent)
	theme.set_color("font_unselected_color", "TabBar", col_muted)
	
	var err = ResourceSaver.save(theme, "res://assets/ui/theme.tres")
	if err == OK:
		print("Theme successfully generated at res://assets/ui/theme.tres")
		quit(0)
	else:
		print("Failed to save theme: ", err)
		quit(1)
