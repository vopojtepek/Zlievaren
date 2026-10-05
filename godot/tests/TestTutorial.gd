extends SceneTree
var main: Node
var tutorial: Node
var gm: Node
var clock: Node
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error(message)

func settle() -> void:
	for i in range(8): await process_frame

func wait_step(expected: int) -> void:
	await settle()
	if tutorial.step() != expected:
		print("State: ", gm.state.tutorial, " target ", tutorial.target, " card ", tutorial.card.size)
		quit(1)
		return
	check(tutorial.step() == expected, "Expected tutorial step %d, got %d" % [expected, tutorial.step()])

func press(control: Button) -> void:
	check(control != null and not control.disabled, "Target button must be enabled")
	if control != null: control.pressed.emit()
	await settle()

func snapshot(label_text: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/tutorial-" + label_text + ".png")

func hire_missing() -> void:
	var attempts := 0
	while tutorial.step() in [1, 2, 3, 4]:
		attempts += 1
		if attempts > 35:
			quit(1)
			return
		await settle()
		match tutorial.step():
			1: await press(tutorial.layout.nav_buttons.office)
			2: await press(main.office_view.btn_tab_hire)
			3:
				if tutorial.target != null: await press(tutorial.target)
			4:
				var grid: Control = tutorial.target
				check(grid != null, "Current shift candidate grid exists")
				if grid == null: return
				await snapshot("candidates-%d" % root.size.x)
				await press(grid.get_child(0).action_button)
	await settle()

func run() -> void:
	root.size = Vector2i(1440, 1000)
	gm = root.get_node("GameManager")
	clock = root.get_node("SimulationClock")
	clock.set_physics_process(false)
	root.get_node("SaveManager").set_process(false)
	main = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await settle()
	for child in main.get_node("UI").get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("TutorialController.gd"):
			tutorial = child
	gm.new_game()
	await wait_step(0)
	check(clock.tutorial_hold and not clock.is_paused, "Tutorial holds time without blocking game commands")
	await snapshot("welcome")
	await press(tutorial.next_button)
	await hire_missing()
	await wait_step(5)
	await press(tutorial.layout.nav_buttons.warehouse)
	await wait_step(6)
	await press(tutorial.target)
	await wait_step(7)
	tutorial.market().quantity.value = 1
	await wait_step(8)
	# Restore a buy checkpoint with a newly-created market ticket (default 10 kg).
	gm.state = FoundryEngine.restore(JSON.stringify(gm.state))
	tutorial.market().quantity.value = 10
	tutorial.last_step = -1
	await wait_step(8)
	check(tutorial.market().quantity.value == 1, "Restored purchase reconstructs quantity")
	var before: int = gm.state.incoming.zinc
	tutorial.target.pressed.emit()
	check(gm.state.tutorial.step == 9, "Purchase checkpoint committed before next frame")
	await settle()
	check(gm.state.incoming.zinc == before + 1, "Real purchase is delivered to ramp")
	await wait_step(9)
	await press(tutorial.target)
	await wait_step(10)
	tutorial.target.pressed.emit()
	check(gm.state.tutorial.step == 11, "Storage checkpoint committed before next frame")
	await settle()
	check(gm.state.incoming.zinc == 0 and gm.state.raw.zinc == 21, "Real zinc stored")
	await wait_step(11)
	await press(tutorial.target)
	await wait_step(12)
	await press(tutorial.target)
	await wait_step(13)
	await press(tutorial.target)
	await wait_step(14)
	main.machine_inspector.product_select.get_popup().id_pressed.emit(0)
	await wait_step(15)
	var money_before: int = gm.state.money
	var failed_result: Dictionary = gm.execute({"type": "trade", "side": "buy", "item": "raw:iron", "quantity": 1000})
	check(not failed_result.ok, "Failed command must fail")
	await wait_step(15)
	check(gm.state.money == money_before, "Failed action has no economic effect")
	await press(tutorial.target)
	await wait_step(16)
	# Preserve actual recipe and risk; a deterministic rejection exercises recovery.
	gm.state.machines[0].reject = true
	for i in range(240):
		if tutorial.step() in [1, 2, 3, 4]: await hire_missing()
		if tutorial.step() != 16: break
		FoundryEngine.tick(gm.state, 0.25)
		root.get_node("EventBus").tick_processed.emit(gm.state, 0.25)
		await settle()
	await wait_step(15)
	check(gm.state.scrapped > 0, "Rejected batch recorded")
	await press(tutorial.target)
	await wait_step(16)
	gm.state.machines[0].reject = false
	# Round-trip save in production; load uses the normal engine restore path.
	var restored: Dictionary = FoundryEngine.restore(JSON.stringify(gm.state))
	check(restored.tutorial.step == 16, "Tutorial step persisted")
	gm.state = restored
	gm.state.machines[0].reject = false
	tutorial.last_step = -1
	await wait_step(16)
	for i in range(240):
		if tutorial.step() in [1, 2, 3, 4]: await hire_missing()
		if tutorial.step() != 16: break
		FoundryEngine.tick(gm.state, 0.25)
		root.get_node("EventBus").tick_processed.emit(gm.state, 0.25)
		await settle()
	await wait_step(17)
	await press(tutorial.target)
	await wait_step(18)
	for i in range(24):
		if tutorial.step() in [1, 2, 3, 4]: await hire_missing()
		if tutorial.step() != 18: break
		FoundryEngine.tick(gm.state, 0.25)
		root.get_node("EventBus").tick_processed.emit(gm.state, 0.25)
		await settle()
	await wait_step(19)
	await press(tutorial.target)
	await wait_step(20)
	await press(tutorial.target)
	await wait_step(21)
	main.washer_inspector.product_select.get_popup().id_pressed.emit(0)
	await wait_step(22)
	await press(tutorial.target)
	await wait_step(23)
	for i in range(100):
		if tutorial.step() in [1, 2, 3, 4]: await hire_missing()
		if tutorial.step() != 23: break
		FoundryEngine.tick(gm.state, 0.25)
		root.get_node("EventBus").tick_processed.emit(gm.state, 0.25)
		await settle()
	await wait_step(24)
	await press(tutorial.target)
	await wait_step(25)
	await press(tutorial.target)
	await settle()
	if tutorial.step() == 26: await press(tutorial.target)
	await settle()
	if tutorial.step() == 27: await press(tutorial.target)
	await settle()
	if tutorial.step() == 28:
		tutorial.market().quantity.value = 1
		await settle()
	await wait_step(29)
	await press(tutorial.target)
	await wait_step(30)
	check(gm.state.sold == 1 and gm.state.goods.clean_iron_pipe == 0, "One real cleaned pipe sold")
	await press(tutorial.next_button)
	check(not tutorial.active() and not clock.tutorial_hold, "Completion releases simulation")
	var legacy: Dictionary = FoundryEngine.fresh()
	gm.state = FoundryEngine.restore(JSON.stringify(legacy))
	await settle()
	check(not tutorial.active(), "Legacy save does not activate tutorial")
	gm.new_game()
	await wait_step(0)
	tutorial.finish("skipped")
	check(gm.state.tutorial.status == "skipped" and not clock.tutorial_hold, "Skip releases clock")
	# Visual coverage at narrow width, preserving the real candidate selection.
	root.size = Vector2i(390, 844)
	root.get_node("DisplayMode").set_mobile(true, false)
	gm.new_game()
	await settle()
	await press(tutorial.next_button)
	await press(tutorial.layout.nav_buttons.office)
	await settle()
	if tutorial.step() == 2: await press(main.office_view.btn_tab_hire)
	await settle()
	if tutorial.step() == 3: await press(tutorial.target)
	await settle()
	await snapshot("mobile-hire")
	check(tutorial.card.get_global_rect().end.x <= 390, "Mobile explanation fits viewport")
	tutorial.finish("skipped")
	main.free()
	print("Tutorial integration: %d failures" % failed)
	quit(1 if failed > 0 else 0)
