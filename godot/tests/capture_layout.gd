extends SceneTree
var main: Node
var layout: Control
var failures: int = 0
func _initialize() -> void:
	call_deferred("capture")
func settle() -> void:
	for i in range(8):
		await process_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func shot(name: String) -> void:
	await settle()
	layout.pause_overlay.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")
func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	root.size = Vector2i(1440, 1000)
	main = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	layout = main.get_node("UI").get_child(main.get_node("UI").get_child_count() - 1)
	var gm = root.get_node("GameManager")
	var clock = root.get_node("SimulationClock")
	var events = root.get_node("EventBus")
	clock.is_paused = true
	# Isolated in-memory state; this test never invokes save/autosave commands.
	gm.state = FoundryEngine.fresh()
	events.tick_processed.emit(gm.state, 0.0)
	layout.pause_overlay.hide()
	await shot("layout-foundry")
	check(layout.page.size.x <= root.size.x, "1440px page fits viewport")
	check(absf(layout.scene.size.x / layout.scene.size.y - 1100.0 / 690.0) < 0.01, "Hall aspect ratio is preserved")
	check(main.machine_inspector.size.x <= 346, "Inspector matches web sidebar width")
	for room in ["warehouse", "washer", "cnc", "office"]:
		gm.change_room(room)
		await shot("layout-" + room)
		check(layout.sidebar.size.x <= 346 or room == "office", "Sidebar width stays consistent in " + room)
		check(main.office_view.visible == (room == "office"), "Office visibility matches navigation")
	gm.change_room("foundry")
	for tab in ["stock", "market", "contracts", "development"]:
		main.management_tabs._switch_tab(tab)
		await settle()
		layout.scroll.scroll_vertical = 2000
		await shot("panel-" + tab)
	layout.scroll.scroll_vertical = 0
	for width in [1920, 1280, 1024, 800]:
		root.size = Vector2i(width, 1000)
		await shot("layout-%d" % width)
		check(layout.page.size.x <= width, "%dpx page fits viewport" % width)
		check(layout.sidebar.get_global_rect().end.x <= width, "%dpx sidebar fits viewport" % width)
	root.size = Vector2i(1440, 1000)
	gm.state = Fixtures.fresh()
	var s: Dictionary = gm.state
	var m: Dictionary = s.machines[0]
	m.state = "working"
	m.elapsed = 8.2
	m.reject = false
	m.served = true
	s.delivery = {"slot": 0, "returnElapsed": null, "crew": 0, "employeeId": FoundryEngine.duty(s, "ladle").id}
	main.foundry_hall.time = 8.2
	events.tick_processed.emit(s, 0)
	layout.pause_overlay.hide()
	await shot("animation-pouring")
	m.elapsed = 18.0
	s.delivery = null
	events.tick_processed.emit(s, 0)
	layout.pause_overlay.hide()
	await shot("animation-cooling")
	check(FoundryEngine.stage(m) == "cooling", "Cooling sample reaches actual cooling stage")
	m.state = "failed"
	m.failedElapsed = 1.2
	events.tick_processed.emit(s, 0)
	layout.pause_overlay.hide()
	await shot("animation-reject")
	events.pause_toggled.emit(true)
	check(layout.pause_overlay.visible, "Pause overlay is shown")
	print("LAYOUT CHECKS: " + str(failures) + " failures")
	quit(1 if failures else 0)
