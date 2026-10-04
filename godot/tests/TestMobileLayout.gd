extends SceneTree
var failures = 0
var layout: Control
var main: Node
var mode: Node

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in range(12):
		await process_frame

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func fits(node: Control, name: String) -> void:
	check(node.get_global_rect().position.x >= -1, name + " left edge fits screen")
	check(node.get_global_rect().end.x <= root.size.x + 1, name + " fits screen: " + str(node.get_global_rect()))

func check_controls(node: Node) -> void:
	if node is BaseButton and node.is_visible_in_tree():
		fits(node, str(node.get_path()))
		check(node.size.x >= 44 and node.size.y >= 44, "Touch target at least 44 px: " + str(node.get_path()))
	for child in node.get_children():
		check_controls(child)

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	layout.pause_overlay.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/mobile-" + name + ".png")

func run() -> void:
	mode = root.get_node("DisplayMode")
	var original_mobile: bool = mode.mobile
	var original_manual: bool = mode.manual
	mode.settings_path = "user://test-display.cfg"
	mode.manual = false
	root.size = Vector2i(850,800)
	await settle()
	mode._viewport_changed()
	check(not mode.mobile, "850 px uses desktop by default")
	root.size = Vector2i(849,800)
	await settle()
	mode._viewport_changed()
	check(mode.mobile, "849 px uses mobile by default")
	root.size = Vector2i(360, 800)
	mode._viewport_changed()
	check(mode.mobile, "First small screen selects mobile")
	main = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	root.get_node("SimulationClock").is_paused = true
	root.get_node("GameManager").state = Fixtures.fresh()
	layout = get_first_node_in_group("responsive_ui")
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	for dimensions in [Vector2i(360,800), Vector2i(390,844), Vector2i(844,390), Vector2i(1920,1080)]:
		root.size = dimensions
		mode.set_mobile(dimensions.x != 1920, false)
		await settle()
		for room in ["foundry", "warehouse", "washer", "cnc", "office"]:
			root.get_node("GameManager").change_room(room)
			await settle()
			fits(layout.page, "%s %s page" % [dimensions,room])
			fits(layout.workshop, room + " workshop")
			if mode.mobile:
				check_controls(layout)
			if room == "office":
				for office_tab in ["overview", "hire", "payroll"]:
					main.office_view._switch_tab(office_tab)
					await settle()
					if mode.mobile:
						check_controls(layout)
					layout.scroll.scroll_vertical = 800
					await settle()
					await shot("%d-office-%s" % [dimensions.x, office_tab])
				for tab in ["stock", "market", "contracts", "development", "ledger"]:
					main.management_tabs._switch_tab(tab)
					await settle()
					fits(main.management_tabs, tab)
					if mode.mobile:
						check_controls(layout)
					layout.scroll.scroll_vertical = 100000
					await settle()
					await shot("%d-%s" % [dimensions.x, tab])
			layout.scroll.scroll_vertical = 0
			await settle()
			await shot("%d-%s" % [dimensions.x,room])
	root.size = Vector2i(360,800)
	mode.set_mobile(true, false)
	root.get_node("GameManager").change_room("foundry")
	await settle()
	var game = root.get_node("GameManager")
	game.state.machines[0].state = "working"
	game.state.machines[0].elapsed = 8.2
	var before = JSON.stringify(game.state)
	main.top_hud.mode_button.pressed.emit()
	await settle()
	check(not mode.mobile, "Button selects desktop")
	check(JSON.stringify(game.state) == before and game.current_room == "foundry" and root.get_node("SimulationClock").is_paused, "Switch preserves simulation, room and pause")
	mode.load_preference()
	check(mode.manual and not mode.mobile, "Manual preference reloads")
	mode._viewport_changed()
	check(not mode.mobile, "Manual preference overrides small viewport")
	game.new_game()
	check(not mode.mobile and mode.manual, "New game retains display preference")
	mode.set_mobile(true, false)
	await settle()
	var point: Vector2 = Vector2(365,300) * main.room_container.scale
	var touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	layout._hall_input(touch)
	check(not layout.machine_modal.visible, "Touch press does not activate")
	touch.pressed = false
	layout._hall_input(touch)
	check(layout.machine_modal.visible, "Tap selects machine without hover")
	await settle()
	fits(layout.machine_modal.panel, "Machine modal")
	check_controls(layout.machine_modal)
	await shot("machine-modal")
	root.size = Vector2i(844,390)
	await settle()
	fits(layout.machine_modal.panel, "Landscape modal")
	check(layout.machine_modal.panel.size.y <= 390, "Modal height follows rotation")
	root.size = Vector2i(360,800)
	await settle()
	layout.machine_modal.close()
	touch.pressed = true
	layout._hall_input(touch)
	var drag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = point + Vector2(0,50)
	layout._hall_input(drag)
	touch.pressed = false
	layout._hall_input(touch)
	check(not layout.machine_modal.visible, "Scroll gesture does not activate machine")
	game.change_room("warehouse")
	await settle()
	touch.position = point
	touch.pressed = true
	layout._hall_input(touch)
	touch.pressed = false
	layout._hall_input(touch)
	check(layout.machine_modal.visible and game.selected_bin == "iron", "Tap selects bin without hover")
	layout.machine_modal.close()
	game.change_room("washer")
	await settle()
	touch.position = Vector2(500,300) * main.room_container.scale
	touch.pressed = true
	layout._hall_input(touch)
	touch.pressed = false
	layout._hall_input(touch)
	check(layout.machine_modal.visible, "Tap opens washer")
	layout.machine_modal.close()
	main.top_hud._show_info("Ako hrať", load("res://src/core/HelpText.gd").HELP)
	await settle()
	var help = main.top_hud.get_child(main.top_hud.get_child_count()-1)
	check(help.size.x <= 360 and help.size.y <= 800, "Help fits screen")
	help.canceled.emit()
	await settle()
	main.top_hud._on_new_game_pressed()
	await settle()
	var dialog = main.top_hud.get_child(main.top_hud.get_child_count()-1)
	check(dialog.size.x <= 360 and dialog.size.y <= 800, "New game confirmation fits")
	dialog.canceled.emit()
	DirAccess.remove_absolute(mode.settings_path)
	mode.settings_path = mode.SETTINGS_PATH
	mode.manual = original_manual
	mode.set_mobile(original_mobile, false)
	main.queue_free()
	await settle()
	print("MOBILE CHECKS: %d failures" % failures)
	quit(1 if failures else 0)
