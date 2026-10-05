class_name TopHUD
extends PanelContainer
var display_mode: Node:
	get:
		return get_node('/root/DisplayMode')

const DISPLAY = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var money_label: Label
var rep_label: Label
var day_label: Label
var clock_label: Label
var revenue_label: Label
var btn_pause: Button
var day_track: ProgressBar
var inspector_modal_open: bool = false
var mode_button: Button
var header_row: BoxContainer

func _label(parent: Node, text: String, font_size: int, color: String = "#e8f0ed") -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(color))
	parent.add_child(l)
	return l

func _stat(parent: Node, title: String) -> Label:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(box)
	_label(box, title, 11, "#9ab1b6")
	var val = _label(box, "0", 29)
	val.add_theme_font_override("font", DISPLAY)
	return val

func _ready() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	custom_minimum_size = Vector2(0, 100)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#101b22")
	style.border_color = Color("#304750")
	style.border_width_bottom = 1
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	var row = BoxContainer.new()
	header_row = row
	row.add_theme_constant_override("separation", 28)
	add_child(row)
	var identity = BoxContainer.new()
	identity.set_meta("keep_horizontal", true)
	identity.add_theme_constant_override("separation", 20)
	row.add_child(identity)
	var brand = _label(identity, "◉  ŽERAVÁ\n    ZLIEVAREŇ", 25)
	brand.size_flags_horizontal = SIZE_EXPAND_FILL
	brand.add_theme_font_override("font", DISPLAY)
	identity.add_child(VSeparator.new())
	var clock_box = VBoxContainer.new()
	clock_box.set_meta("responsive_minimum", true)
	clock_box.custom_minimum_size.x = 150
	clock_box.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_child(clock_box)
	day_label = _label(clock_box, "DEŇ 1 · TÝŽDEŇ 1", 11, "#9ab1b6")
	clock_label = _label(clock_box, "06:00", 31)
	clock_label.add_theme_font_override("font", DISPLAY)
	day_track = ProgressBar.new()
	day_track.show_percentage = false
	day_track.custom_minimum_size.y = 3
	clock_box.add_child(day_track)
	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(spacer)
	var stats = BoxContainer.new()
	stats.set_meta("keep_horizontal", true)
	stats.size_flags_horizontal = SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation", 20)
	row.add_child(stats)
	money_label = _stat(stats, "KAPITÁL")
	money_label.add_theme_color_override("font_color", Color("#ffa75f"))
	revenue_label = _stat(stats, "TRŽBY")
	rep_label = _stat(stats, "REPUTÁCIA")
	var controls = BoxContainer.new()
	controls.set_meta("keep_horizontal", true)
	controls.size_flags_horizontal = SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 8)
	row.add_child(controls)
	btn_pause = Button.new()
	btn_pause.text = "Ⅱ"
	btn_pause.tooltip_text = "Pauza (P)"
	btn_pause.custom_minimum_size = Vector2(39, 39)
	btn_pause.size_flags_vertical = SIZE_SHRINK_CENTER
	btn_pause.size_flags_horizontal = SIZE_EXPAND_FILL
	btn_pause.pressed.connect(_on_pause_pressed)
	controls.add_child(btn_pause)
	for entry in [["?", "Ako hrať", preload("res://src/core/HelpText.gd").HELP], ["Novinky", "Novinky", preload("res://src/core/HelpText.gd").NEWS]]:
		var b = Button.new()
		b.text = entry[0]
		b.tooltip_text = entry[1]
		b.custom_minimum_size.y = 39
		b.size_flags_vertical = SIZE_SHRINK_CENTER
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		var title: String = entry[1]
		var body: String = entry[2]
		b.pressed.connect(func(): _show_info(title, body))
		controls.add_child(b)
	var new_game_button = Button.new()
	var game_actions = BoxContainer.new()
	game_actions.set_meta("keep_horizontal", true)
	row.add_child(game_actions)
	new_game_button.text = "Nová hra"
	new_game_button.custom_minimum_size.y = 39
	new_game_button.size_flags_vertical = SIZE_SHRINK_CENTER
	new_game_button.size_flags_horizontal = SIZE_EXPAND_FILL
	new_game_button.pressed.connect(_on_new_game_pressed)
	game_actions.add_child(new_game_button)
	mode_button = Button.new()
	mode_button.custom_minimum_size.y = 39
	mode_button.size_flags_vertical = SIZE_SHRINK_CENTER
	mode_button.size_flags_horizontal = SIZE_EXPAND_FILL
	mode_button.pressed.connect(func(): display_mode.set_mobile(not display_mode.mobile))
	game_actions.add_child(mode_button)
	display_mode.mode_changed.connect(func(_mobile): _update_display())
	_update_display()
	EventBus.tick_processed.connect(_on_tick)
	EventBus.pause_toggled.connect(func(paused): btn_pause.text = "▶" if paused else "Ⅱ")
	resized.connect(func():
		if revenue_label != null:
			revenue_label.get_parent().visible = display_mode.mobile or size.x > 1000
			rep_label.get_parent().visible = display_mode.mobile or size.x > 850
	)
	_on_tick(GameManager.state, 0)

func _update_display() -> void:
	header_row.add_theme_constant_override("separation", 12 if display_mode.mobile else 28)
	mode_button.text = "Desktopové zobrazenie" if display_mode.mobile else "Mobilné zobrazenie"
	revenue_label.get_parent().visible = display_mode.mobile or size.x > 1000
	rep_label.get_parent().visible = display_mode.mobile or size.x > 850

func _unhandled_key_input(event: InputEvent) -> void:
	if inspector_modal_open or SimulationClock.tutorial_active:
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var focus = get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_6:
		GameManager.select_machine(event.keycode - KEY_1)
		if GameManager.current_room == "foundry":
			EventBus.machine_inspector_requested.emit(event.keycode - KEY_1)
	elif event.keycode == KEY_P:
		_on_pause_pressed()
	elif event.keycode == KEY_SPACE and GameManager.current_room == "foundry":
		var m = GameManager.state.machines[GameManager.selected_machine]
		if m != null:
			GameManager.execute({"type": "machine", "slot": GameManager.selected_machine, "action": "collect" if m.state == "ready" else "cast"})
	else:
		return
	get_viewport().set_input_as_handled()

func _on_pause_pressed() -> void:
	EventBus.pause_toggled.emit(not SimulationClock.is_paused)

func _on_tick(state: Dictionary, _delta: float) -> void:
	if state.is_empty():
		return
	money_label.text = Format.cash(state.money)
	revenue_label.text = Format.cash(state.revenue)
	rep_label.text = str(state.reputation)
	day_label.text = "DEŇ %d · TÝŽDEŇ %d" % [FoundryEngine.day(state), FoundryEngine.week(state)]
	clock_label.text = FoundryEngine.clock_text(state)
	day_track.value = fmod(float(state.clock), Constants.DAY) / Constants.DAY * 100.0

func _show_info(title: String, body: String) -> void:
	var was_paused = SimulationClock.is_paused
	EventBus.pause_toggled.emit(true)
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.ok_button_text = "Pokračovať"
	add_child(dialog)
	var text = RichTextLabel.new()
	text.text = body
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.offset_left = 22
	text.offset_top = 16
	text.offset_right = -22
	text.offset_bottom = -60
	dialog.add_child(text)
	dialog.confirmed.connect(func():
		EventBus.pause_toggled.emit(was_paused)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		EventBus.pause_toggled.emit(was_paused)
		dialog.queue_free()
	)
	dialog.popup_centered_clamped(Vector2i(560, 720))
	dialog.get_ok_button().custom_minimum_size = Vector2(44, 44)

func _on_new_game_pressed() -> void:
	var was_paused = SimulationClock.is_paused
	EventBus.pause_toggled.emit(true)
	var dialog = ConfirmationDialog.new()
	dialog.title = "Nová hra"
	dialog.dialog_text = "Začať novú hru? Aktuálny uložený postup sa prepíše."
	dialog.ok_button_text = "Začať novú hru"
	dialog.cancel_button_text = "Zrušiť"
	add_child(dialog)
	dialog.confirmed.connect(func():
		GameManager.new_game()
		SaveManager.save_game()
		EventBus.tick_processed.emit(GameManager.state, 0.0)
		EventBus.pause_toggled.emit(false)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		EventBus.pause_toggled.emit(was_paused)
		dialog.queue_free()
	)
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.get_label().custom_minimum_size.x = mini(280, int(get_viewport_rect().size.x - 64))
	dialog.get_ok_button().custom_minimum_size.y = 44
	dialog.get_cancel_button().custom_minimum_size.y = 44
	dialog.popup_centered_clamped(Vector2i(320, 200))
