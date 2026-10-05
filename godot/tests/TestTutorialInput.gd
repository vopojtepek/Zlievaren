extends SceneTree
var main: Node
var tutorial: Node
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in range(32): await process_frame
func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()
func run() -> void:
	root.size = Vector2i(1440, 1000)
	root.get_node("SimulationClock").set_physics_process(false)
	root.get_node("SaveManager").set_process(false)
	root.get_node("DisplayMode").set_mobile(false, false)
	main = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await settle()
	for child in main.get_node("UI").get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("TutorialController.gd"): tutorial = child
	var gm := root.get_node("GameManager")
	for width in [1440, 390]:
		root.size = Vector2i(width, 1000 if width == 1440 else 844)
		root.get_node("DisplayMode").set_mobile(width == 390, false)
		gm.new_game()
		await settle()
		await click(tutorial.next_button)
		assert(tutorial.step() == 1)
		await click(tutorial.layout.nav_buttons.warehouse)
		assert(gm.current_room == "foundry", "Outside clicks blocked")
		await click(tutorial.target)
		assert(tutorial.step() == 2, "Office click: step=" + str(tutorial.step()) + " room=" + gm.current_room + " hover=" + str(root.gui_get_hovered_control()))
		await click(tutorial.target)
		assert(tutorial.step() == 3)
		await click(tutorial.target)
		assert(tutorial.step() == 4)
		var candidate: Control = tutorial.target.get_child(0)
		await click(candidate.action_button)
		assert(FoundryEngine.duty(gm.state, "ladle") != null, "Real pointer click hires candidate")
		var event := InputEventKey.new()
		event.pressed = true
		event.keycode = KEY_P
		Input.parse_input_event(event)
		await settle()
		assert(not root.get_node("SimulationClock").is_paused, "Pause shortcut blocked")
		# Dropdown selection invokes the existing Godot PopupMenu path.
		for role in tutorial.ROLES:
			var key: String = tutorial.role_key(role)
			if FoundryEngine.assigned(gm.state, key) == null:
				FoundryEngine.perform(gm.state, {"type": "personnel", "action": "hire", "position": key, "candidateId": gm.state.hr.candidates[key][0].id})
		tutorial.advance(14)
		await settle()
		await click(tutorial.target)
		assert(main.machine_inspector.product_select.get_popup().visible, "Real click opens product popup")
		main.machine_inspector.product_select.get_popup().id_pressed.emit(0)
		main.machine_inspector.product_select.get_popup().hide()
		await settle()
		assert(tutorial.step() == 15, "Selecting the default recipe confirms it")
		await click(tutorial.target)
		assert(tutorial.step() == 16 and gm.state.machines[0].state == "working", "Real click starts manufacturing")
		var raw_before: int = gm.state.raw.iron
		await click(tutorial.skip_button)
		assert(gm.state.tutorial.status == "skipped" and gm.state.raw.iron == raw_before and gm.state.machines[0].state == "working", "Skip preserves active work")
		assert(not root.get_node("SimulationClock").tutorial_hold)
	main.free()
	print("Tutorial input: pointer actions, blocked controls/shortcuts, dropdown and skip passed")
	quit()
