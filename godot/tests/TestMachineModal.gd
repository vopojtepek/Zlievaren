extends SceneTree

var failures := 0
var main: Node
var layout: Control
var gm: Node
var events: Node
var clock: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func settle() -> void:
	for i in range(8):
		await process_frame

func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	Input.parse_input_event(event)
	await process_frame

func shot(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + filename + ".png")

func click_at(position: Vector2) -> void:
	root.warp_mouse(position)
	var motion = InputEventMouseMotion.new()
	motion.position = position
	Input.parse_input_event(motion)
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	Input.parse_input_event(event)
	await settle()

func run() -> void:
	gm = root.get_node("GameManager")
	events = root.get_node("EventBus")
	clock = root.get_node("SimulationClock")
	# Never write the player's save, even when testing real inspector actions.
	root.get_node("SaveManager").set_process(false)
	root.size = Vector2i(1440, 1000)
	main = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	layout = main.get_node("UI").get_child(main.get_node("UI").get_child_count() - 1)
	gm.new_game()
	clock.set_physics_process(false)
	clock.is_paused = false
	await settle()
	var modal = layout.machine_modal
	var inspector = main.machine_inspector
	check(not modal.visible, "New game does not open modal")
	gm.select_machine(2)
	check(not modal.visible, "Selection/load notification does not open modal")
	check(not layout.sidebar.visible and not main.management_tabs.visible, "Foundry hides sidebar and management tabs")
	check(absf(layout.workshop.size.x - layout.columns.size.x) < 1, "Workshop fills columns")
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	await shot("foundry-full-width")
	# Headless DisplayServer cannot warp the OS pointer used by the hall hit test.
	if DisplayServer.get_name() != "headless":
		var slot_position: Vector2 = main.foundry_hall.to_global(main.foundry_hall.POSITIONS[0] - Vector2(0, 40))
		await click_at(slot_position)
		check(modal.visible and inspector.slot == 0, "Clicking rendered machine opens modal")
		modal.close()
		var empty_position: Vector2 = main.foundry_hall.to_global(main.foundry_hall.POSITIONS[2] - Vector2(0, 40))
		await click_at(empty_position)
		check(modal.visible and inspector.slot == 2, "Clicking rendered empty slot opens purchase modal")
		modal.open_slot(0)
		# This empty slot is visible outside the modal, underneath its backdrop.
		await click_at(empty_position)
		check(not modal.visible and inspector.slot == 0, "Backdrop prevents click-through to another machine")
	for slot in range(6):
		events.machine_inspector_requested.emit(slot)
		await settle()
		check(modal.visible and inspector.slot == slot, "Correct modal for slot %d" % slot)
		check(inspector.purchase_controls.visible == (slot != 0), "Empty slot purchase controls %d" % slot)
		check(not clock.is_paused, "Opening does not pause production")
		modal.close()
	await key(KEY_1)
	check(modal.visible and inspector.slot == 0, "Keyboard opens modal")
	await key(KEY_3)
	check(inspector.slot == 2, "Keyboard switches modal slot")
	# Real purchase action must target only the selected empty slot.
	gm.state.money = 10000
	inspector._on_buy_machine()
	events.tick_processed.emit(gm.state, 0.0)
	check(gm.state.machines[2] != null and gm.state.machines[1] == null, "Purchase targets selected slot")
	check(inspector.owned_controls.visible, "Purchase refreshes live inspector")
	inspector._on_auto_toggled(true)
	check(gm.state.machines[2].auto and not gm.state.machines[0].auto, "Automation targets selected slot")
	gm.state.machines[2].state = "working"
	gm.state.machines[2].elapsed = 5.0
	events.tick_processed.emit(gm.state, 0.0)
	check(inspector.cycle_bar.value > 0, "Production updates in open modal")
	await key(KEY_ESCAPE)
	check(not modal.visible, "Escape closes modal")
	events.pause_toggled.emit(true)
	modal.open_slot(0)
	check(clock.is_paused and inspector.btn_action.disabled, "Manual pause is retained")
	modal.close()
	check(clock.is_paused, "Closing preserves manual pause")
	events.pause_toggled.emit(false)
	modal.open_slot(0)
	await settle()
	inspector.product_select.show_popup()
	await settle()
	await key(KEY_ESCAPE)
	check(modal.visible and not inspector.product_select.get_popup().visible, "First Escape closes only product popup")
	modal.close_button.grab_focus()
	for i in range(25):
		await key(KEY_TAB)
		check(modal.is_ancestor_of(root.gui_get_focus_owner()), "Keyboard focus stays inside modal")
	modal.open_slot(0)
	await settle()
	for toast in main.toast_manager.container.get_children():
		toast.queue_free()
	await settle()
	await shot("machine-modal-wide")
	for viewport_size in [Vector2i(800, 600), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await settle()
		check(modal.panel.get_global_rect().end.x <= root.size.x and modal.panel.get_global_rect().end.y <= root.size.y, "Modal fits viewport")
		if viewport_size.x == 800:
			check(modal.content_scroll.get_v_scroll_bar().max_value > modal.content_scroll.size.y, "Small modal scrolls")
			await shot("machine-modal-small")
	for room in ["warehouse", "washer", "cnc", "office"]:
		gm.change_room(room)
		await settle()
		check(not modal.visible, "Room navigation closes modal")
		check(main.management_tabs.visible, "Other rooms keep management tabs")
		check(layout.sidebar.visible == (room != "office"), "Other rooms keep sidebar behavior")
		gm.change_room("foundry")
		modal.open_slot(0)
	inspector.btn_goto_office.pressed.emit()
	check(gm.current_room == "office" and not modal.visible, "Inspector office action closes modal")
	gm.change_room("foundry")
	modal.open_slot(0)
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(4, 4)
	Input.parse_input_event(click)
	await settle()
	check(not modal.visible, "Backdrop click closes modal")
	check(not layout.sidebar.visible and not main.management_tabs.visible, "Returning to foundry keeps simplified layout")
	print("MACHINE MODAL CHECKS: %d failures" % failures)
	main.queue_free()
	await settle()
	quit(1 if failures else 0)
