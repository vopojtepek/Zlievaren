extends Control
## Native Godot layout following the web app's 1640px page and 1100:690 canvas.
const DISPLAY = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var main: Node
var scroll: ScrollContainer
var page: VBoxContainer
var columns: BoxContainer
var workshop: VBoxContainer
var scene: Control
var sidebar: VBoxContainer
var heading: Label
var eyebrow: Label
var metrics: Label
var live: Label
var crew: Label
var duty_label: Label
var payroll: Label
var goal_title: Label
var goal_value: Label
var goal_bar: ProgressBar
var shift_cards: Array[Button] = []
var nav_buttons: Dictionary = {}
var pause_overlay: PanelContainer
var alert: Button
var office: Control
var scene_info: VBoxContainer
var area_switch: Button

static func panel_style(color: String = "#1f333b", padding: float = 20.0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(color)
	s.border_color = Color("#304750")
	s.set_border_width_all(1)
	s.set_corner_radius_all(10)
	s.set_content_margin_all(padding)
	return s

func label_node(parent: Node, text: String, font_size: int = 12, color: String = "#9ab1b6") -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(color))
	parent.add_child(l)
	return l

func button_node(parent: Node, text: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 36
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func adopt(control: Control, parent: Node) -> void:
	control.reparent(parent)
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.custom_minimum_size = Vector2.ZERO
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_FILL

func build(root: Node) -> void:
	main = root
	main.toast_manager.z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll = ScrollContainer.new()
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var center = HBoxContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(center)
	var left = Control.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	center.add_child(left)
	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 23)
	center.add_child(page)
	var right = Control.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	center.add_child(right)
	adopt(main.top_hud, page)
	main.top_hud.custom_minimum_size.y = 100
	columns = BoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	page.add_child(columns)
	workshop = VBoxContainer.new()
	workshop.size_flags_horizontal = SIZE_EXPAND_FILL
	workshop.add_theme_constant_override("separation", 12)
	columns.add_child(workshop)
	var head = HBoxContainer.new()
	workshop.add_child(head)
	var titles = VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(titles)
	eyebrow = label_node(titles, "HALA 01 / ODSTREDIVÉ ODLIEVANIE", 11)
	heading = label_node(titles, "Tvoja zlievareň.", 33, "#e8f0ed")
	heading.add_theme_font_override("font", DISPLAY)
	metrics = label_node(head, "1 / 6 strojov · 0 predaných")
	var navigation = HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 8)
	workshop.add_child(navigation)
	for entry in [["foundry", "Zlievareň"], ["warehouse", "Sklad"], ["washer", "Pieskovač"], ["cnc", "CNC hala"], ["office", "Kancelária"]]:
		var id: String = entry[0]
		var b = button_node(navigation, entry[1], func(): GameManager.change_room(id))
		b.toggle_mode = true
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 42
		var nav_style = panel_style("#365d72", 8)
		nav_style.border_color = Color("#87bacd")
		b.add_theme_stylebox_override("pressed", nav_style)
		b.add_theme_color_override("font_pressed_color", Color("#f0f6f2"))
		nav_buttons[id] = b
	alert = button_node(workshop, "", func(): GameManager.change_room("office"))
	alert.add_theme_color_override("font_color", Color("#ffb293"))
	alert.alignment = HORIZONTAL_ALIGNMENT_LEFT
	alert.add_theme_font_size_override("font_size", 12)
	var alert_style = panel_style("#624831", 12)
	alert_style.border_color = Color("#bb8055")
	alert.add_theme_stylebox_override("normal", alert_style)
	scene = Control.new()
	scene.name = "HallCanvas"
	scene.clip_contents = true
	scene.mouse_filter = MOUSE_FILTER_STOP
	workshop.add_child(scene)
	main.room_container.reparent(scene)
	main.room_container.position = Vector2.ZERO
	for room in main.room_container.get_children():
		room.set_process_input(false)
	scene.gui_input.connect(func(event):
		for room in main.room_container.get_children():
			if room.visible:
				room._input(event)
	)
	var badges = HBoxContainer.new()
	scene.add_child(badges)
	badges.set_anchors_and_offsets_preset(PRESET_TOP_WIDE)
	badges.offset_left = 18
	badges.offset_right = -18
	badges.offset_top = 15
	badges.mouse_filter = MOUSE_FILTER_IGNORE
	live = label_node(badges, "DIELŇA PRIPRAVENÁ", 10, "#d6e3d9")
	live.size_flags_horizontal = SIZE_SHRINK_BEGIN
	var badge_gap = Control.new()
	badge_gap.size_flags_horizontal = SIZE_EXPAND_FILL
	badges.add_child(badge_gap)
	crew = label_node(badges, "OBSADENIE SMENY", 10, "#d5cdaf")
	for badge in [live, crew]:
		var style = panel_style("#10262bce", 7)
		style.border_color = Color("#576c68")
		style.set_corner_radius_all(4)
		badge.add_theme_stylebox_override("normal", style)
	area_switch = button_node(scene, "TAVIAREŇ → SKLAD", func(): GameManager.change_room("warehouse" if GameManager.current_room == "foundry" else "foundry"))
	area_switch.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	area_switch.offset_left = 18
	area_switch.offset_top = -76
	area_switch.offset_bottom = -40
	area_switch.add_theme_font_size_override("font_size", 10)
	var legend = label_node(scene, "● Odlievanie      ● Chladenie      ● Hotovo                                      1 deň = 3 minúty", 10, "#c4d7d4")
	legend.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE)
	legend.offset_left = 18
	legend.offset_top = -27
	legend.offset_bottom = -10
	pause_overlay = PanelContainer.new()
	scene.add_child(pause_overlay)
	pause_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var shade = panel_style("#0c2029ed")
	pause_overlay.add_theme_stylebox_override("panel", shade)
	var pause_center = CenterContainer.new()
	pause_overlay.add_child(pause_center)
	var pause_box = VBoxContainer.new()
	pause_center.add_child(pause_box)
	label_node(pause_box, "Ⅱ  Prestávka v dielni", 34, "#ffa75f")
	button_node(pause_box, "Pokračovať", main.top_hud._on_pause_pressed)
	office = main.office_view
	adopt(office, workshop)
	office.custom_minimum_size.y = 690
	office.add_theme_stylebox_override("panel", panel_style("#152a35", 24))
	scene_info = VBoxContainer.new()
	scene_info.add_theme_constant_override("separation", 10)
	workshop.add_child(scene_info)
	var shifts = HBoxContainer.new()
	scene_info.add_child(shifts)
	for c in Constants.CREWS:
		var b = button_node(shifts, c.name + "   " + c.hours, func(): GameManager.change_room("office"))
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		shift_cards.append(b)
	duty_label = label_node(scene_info, "", 12, "#d5cdaf")
	var payrow = HBoxContainer.new()
	scene_info.add_child(payrow)
	payroll = label_node(payrow, "", 12)
	payroll.size_flags_horizontal = SIZE_EXPAND_FILL
	button_node(payrow, "Zamestnanci →", func(): GameManager.change_room("office"))
	var goal = PanelContainer.new()
	goal.add_theme_stylebox_override("panel", panel_style("#203638", 15))
	scene_info.add_child(goal)
	var grow = HBoxContainer.new()
	goal.add_child(grow)
	var gtext = VBoxContainer.new()
	gtext.size_flags_horizontal = SIZE_EXPAND_FILL
	grow.add_child(gtext)
	label_node(gtext, "↗  ĎALŠÍ MÍĽNIK", 11)
	goal_title = label_node(gtext, "", 21, "#e8f0ed")
	goal_title.add_theme_font_override("font", DISPLAY)
	var gp = VBoxContainer.new()
	gp.custom_minimum_size.x = 150
	grow.add_child(gp)
	goal_value = label_node(gp, "", 12, "#b4d7b5")
	goal_bar = ProgressBar.new()
	goal_bar.show_percentage = false
	goal_bar.custom_minimum_size.y = 5
	gp.add_child(goal_bar)
	sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 345
	columns.add_child(sidebar)
	for inspector in [main.machine_inspector, main.warehouse_inspector, main.washer_inspector, main.cnc_inspector]:
		adopt(inspector, sidebar)
		inspector.add_theme_stylebox_override("panel", panel_style("#1f333b", 23))
		_wrap_labels(inspector)
	for b in [main.machine_inspector.btn_action, main.machine_inspector.btn_buy_machine, main.washer_inspector.btn_start, main.warehouse_inspector.btn_stock_move]:
		b.add_theme_stylebox_override("normal", panel_style("#ffa75f", 10))
		b.add_theme_color_override("font_color", Color("#272b25"))
	adopt(main.management_tabs, page)
	main.management_tabs.custom_minimum_size.y = 430
	label_node(page, "Postup sa ukladá automaticky.                                                    180 s / deň", 11)
	main.inspectors_container.hide()
	resized.connect(_resize_page)
	scene.resized.connect(_resize_scene)
	EventBus.room_change_requested.connect(_room_changed)
	EventBus.tick_processed.connect(_tick)
	EventBus.pause_toggled.connect(func(_p): _tick(GameManager.state, 0.0))
	_resize_page()
	_room_changed(GameManager.current_room)
	_tick(GameManager.state, 0)

func _wrap_labels(node: Node) -> void:
	for child in node.get_children():
		if child is Label and not child.get_parent() is HBoxContainer:
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if child is OptionButton:
			child.fit_to_longest_item = false
		if child is Button:
			child.clip_text = true
		_wrap_labels(child)

func _resize_page() -> void:
	if page == null:
		return
	var w = minf(1556.0, maxf(640.0, size.x - 64.0))
	page.custom_minimum_size.x = w
	page.size.x = w
	sidebar.custom_minimum_size.x = 345 if size.x >= 1450 else (320 if size.x > 1150 else 290)
	columns.vertical = size.x < 850
	metrics.visible = size.x > 1150
	_resize_scene.call_deferred()

func _resize_scene() -> void:
	var w = scene.size.x
	scene.custom_minimum_size.y = w * 690.0 / 1100.0
	main.room_container.scale = Vector2.ONE * w / 1100.0

func _room_changed(id: String) -> void:
	var names = {"foundry": ["HALA 01 / ODSTREDIVÉ ODLIEVANIE", "Tvoja zlievareň."], "warehouse": ["HALA 02 / SKLADOVÉ HOSPODÁRSTVO", "Sklad a zásoby."], "washer": ["HALA 03 / VODNÉ ČISTENIE", "Pieskovač."], "cnc": ["HALA 04 / REZANIE RÚR", "CNC hala."], "office": ["ĽUDIA A PREVÁDZKA", "Kancelária."]}
	eyebrow.text = names[id][0]
	heading.text = names[id][1]
	for key in nav_buttons:
		nav_buttons[key].set_pressed_no_signal(key == id)
	scene.visible = id != "office"
	scene_info.visible = id != "office"
	sidebar.visible = id != "office"
	main.management_tabs.visible = true
	main.inspectors_container.hide()
	_resize_scene.call_deferred()
	area_switch.text = "TAVIAREŇ → SKLAD" if id == "foundry" else "← TAVIAREŇ"
	_tick(GameManager.state, 0)

func _tick(s: Dictionary, _dt: float) -> void:
	if s.is_empty():
		return
	metrics.text = "%d / 6 strojov · %d predaných" % [FoundryEngine.occupied(s), s.sold]
	var si = FoundryEngine.shift(s)
	for i in range(3):
		shift_cards[i].modulate = Color.WHITE if i == si else Color(1, 1, 1, 0.55)
	var master = FoundryEngine.duty(s, "foreman")
	duty_label.text = "MAJSTER V SLUŽBE   " + (master.name if master != null else "Chýba majster")
	payroll.text = "Mzdy · ďalšia výplata za %d s · dlh %s" % [int(FoundryEngine.next_pay(s) - s.clock), Format.cash(s.payroll.debt)]
	var missing = 0
	for p in FoundryEngine.positions(s):
		if FoundryEngine.position_active(s, p) and FoundryEngine.duty(s, p.role, p.slot) == null:
			missing += 1
	alert.visible = missing > 0 and GameManager.current_room != "office"
	alert.text = "Na smene chýba %d pracovníkov. Doplniť obsadenie v Kancelárii →" % missing
	crew.text = Constants.CREWS[si].shift.to_upper() + " · " + Constants.CREWS[si].name
	var working = 0
	for m in s.machines:
		if m != null and m.state != "idle":
			working += 1
	live.text = "%d STROJOV V PREVÁDZKE" % working if working > 0 else "DIELŇA PRIPRAVENÁ"
	pause_overlay.visible = SimulationClock.is_paused
	for g in Constants.GOALS:
		if not s.milestones.has(g.id):
			goal_title.text = g.name
			var val = FoundryEngine.progress_val(s, g)
			goal_value.text = "%d / %d     +%d ₵" % [val, g.target, g.reward]
			goal_bar.max_value = g.target
			goal_bar.value = val
			return
	goal_title.text = "Všetky míľniky splnené"
	goal_value.text = "Hotovo"
	goal_bar.value = goal_bar.max_value
