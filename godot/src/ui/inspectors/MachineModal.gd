extends Control
## One live inspector, hosted above the page without pausing simulation.
var inspector: Control
var hud: Control
var panel: PanelContainer
var content_scroll: ScrollContainer
var close_button: Button
var previous_focus: Control

func build(machine: Control, top_hud: Control) -> void:
	name = "MachineModal"
	inspector = machine
	hud = top_hud
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color("#071219bb")
	shade.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	panel = PanelContainer.new()
	panel.mouse_filter = MOUSE_FILTER_STOP
	add_child(panel)
	var box = VBoxContainer.new()
	panel.add_child(box)
	close_button = Button.new()
	close_button.text = "Zavrieť  ×"
	close_button.size_flags_horizontal = SIZE_SHRINK_END
	close_button.pressed.connect(close)
	box.add_child(close_button)
	content_scroll = ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	content_scroll.follow_focus = true
	box.add_child(content_scroll)
	inspector.reparent(content_scroll)
	inspector.set_anchors_and_offsets_preset(PRESET_TOP_LEFT)
	inspector.custom_minimum_size = Vector2.ZERO
	inspector.size_flags_horizontal = SIZE_EXPAND_FILL
	inspector.show()
	gui_input.connect(_backdrop_input)
	resized.connect(_resize_panel)
	EventBus.machine_inspector_requested.connect(open_slot)
	EventBus.room_change_requested.connect(func(_room): close())
	get_viewport().gui_focus_changed.connect(_keep_focus_inside)
	hide()
	_resize_panel()

func _keep_focus_inside(control: Control) -> void:
	if visible and not is_ancestor_of(control) and not inspector.product_select.get_popup().visible:
		close_button.grab_focus()

func _resize_panel() -> void:
	if panel == null:
		return
	panel.size = Vector2(minf(560, maxf(0, size.x - 32)), minf(860, maxf(0, size.y - 32)))
	panel.position = (size - panel.size) / 2

func open_slot(slot: int) -> void:
	if GameManager.current_room != "foundry" or slot < 0 or slot >= Constants.SLOTS:
		return
	if not visible:
		previous_focus = get_viewport().gui_get_focus_owner()
	GameManager.select_machine(slot)
	content_scroll.scroll_vertical = 0
	show()
	hud.machine_modal_open = true
	_resize_panel()
	close_button.grab_focus()

func close() -> void:
	if not visible:
		return
	inspector.product_select.get_popup().hide()
	hide()
	hud.machine_modal_open = false
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
	else:
		get_viewport().gui_release_focus()

func _backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()
	accept_event()

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	# PopupMenu owns its keyboard events, including the first Escape.
	if inspector.product_select.get_popup().visible:
		return
	if event.keycode == KEY_ESCAPE:
		close()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
		open_slot(event.keycode - KEY_1)
	elif event.keycode == KEY_P:
		hud._on_pause_pressed()
	elif event.keycode == KEY_TAB:
		var focus = get_viewport().gui_get_focus_owner()
		var next: Control = null
		if focus != null:
			next = focus.find_prev_valid_focus() if event.shift_pressed else focus.find_next_valid_focus()
		if next == null or not is_ancestor_of(next):
			close_button.grab_focus()
		else:
			next.grab_focus()
	else:
		return
	get_viewport().set_input_as_handled()
