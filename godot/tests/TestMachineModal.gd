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
		check(main.management_tabs.visible == (room == "office"), "Management tabs only in office")
		check(not layout.sidebar.visible, "Halls have no sidebar")
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
	await check_other_halls(modal)
	print("MACHINE MODAL CHECKS: %d failures" % failures)
	main.queue_free()
	await settle()
	quit(1 if failures else 0)

func check_other_halls(modal: Control) -> void:
	gm.new_game()
	gm.state.money = 10000
	gm.change_room("warehouse")
	if DisplayServer.get_name() != "headless":
		await settle()
		await click_at(main.warehouse_hall.to_global(main.warehouse_hall.BIN_POSITIONS[0] - Vector2(0, 40)))
		check(modal.visible, "Rendered bin click opens modal")
		await click_at(Vector2(4, 150))
		check(not modal.visible, "Warehouse backdrop closes without click-through")
	gm.select_bin("copper")
	check(not modal.visible, "Selecting bin does not open modal")
	for bin_id in ["iron", "zinc", "steel", "copper", "tin", "goods"]:
		events.bin_inspector_requested.emit(bin_id)
		await settle()
		check(modal.visible and main.warehouse_inspector.current_bin == bin_id, "Bin opens: " + bin_id)
		check(not main.machine_inspector.is_visible_in_tree() and not main.washer_inspector.is_visible_in_tree(), "Only selected inspector visible")
		check(not clock.is_paused, "Storage modal keeps simulation running")
		if bin_id == "copper":
			check(not gm.state.binUnlocked.copper, "Copper starts locked")
			main.warehouse_inspector.btn_upgrade.pressed.emit()
			check(gm.state.binUnlocked.copper and not gm.state.binUnlocked.tin, "Unlock targets selected bin")
		await key(KEY_ESCAPE)
		check(not modal.visible, "Storage Escape closes")
	gm.state = Fixtures.fresh()
	gm.state.money = 10000
	gm.change_room("warehouse")
	modal.open_bin("iron")
	var iron_before: int = gm.state.raw.iron
	var incoming_iron: int = gm.state.incoming.iron
	main.warehouse_inspector.btn_stock_move.pressed.emit()
	check(gm.state.raw.iron == iron_before + incoming_iron and gm.state.incoming.iron == 0, "Store action transfers selected material")
	gm.change_room("washer")
	check(not modal.visible, "Changing room closes storage")
	Fixtures.perform(gm.state, {"type": "washer", "action": "configure", "product": "iron_pipe"})
	gm.state.goods.iron_pipe = 4
	events.washer_inspector_requested.emit()
	if DisplayServer.get_name() != "headless":
		modal.close()
		await settle()
		await click_at(main.washer_hall.to_global(Vector2(500, 330)))
	check(modal.visible and gm.state.washer.active == null, "Opening washer does not start cycle")
	main.washer_inspector.product_select.item_selected.emit(2)
	check(gm.state.washer.product == "steel_pipe", "Washer product selection works")
	main.washer_inspector.product_select.item_selected.emit(0)
	main.washer_inspector.btn_start.pressed.emit()
	check(gm.state.washer.active == "iron_pipe", "Washer starts via button")
	main.washer_inspector.check_auto.toggled.emit(true)
	check(gm.state.washer.auto, "Washer automation works")
	FoundryEngine.tick(gm.state, 4.0)
	events.tick_processed.emit(gm.state, 0.0)
	check(main.washer_inspector.progress_bar.value > 0, "Washer progress updates live")
	modal.close()
	events.washer_inspector_requested.emit()
	check(modal.visible, "Running washer can reopen")
	await settle()
	main.washer_inspector.product_select.show_popup()
	await settle()
	await key(KEY_ESCAPE)
	check(modal.visible and not main.washer_inspector.product_select.get_popup().visible, "Washer Escape closes popup first")
	modal.close_button.grab_focus()
	for i in range(15):
		await key(KEY_TAB)
		check(modal.is_ancestor_of(root.gui_get_focus_owner()), "Washer focus trapped")
	events.pause_toggled.emit(true)
	modal.close()
	modal.open_washer()
	check(clock.is_paused, "Washer retains manual pause")
	events.pause_toggled.emit(false)
	for toast in main.toast_manager.container.get_children():
		toast.queue_free()
	await settle()
	for viewport_size in [Vector2i(800, 600), Vector2i(1440, 1000), Vector2i(1920, 1080)]:
		root.size = viewport_size
		for room in ["warehouse", "washer", "cnc"]:
			gm.change_room(room)
			await settle()
			check(not modal.visible, "Navigation leaves modal closed")
			check(absf(layout.workshop.size.x - layout.columns.size.x) < 1, "Full width hall: " + room)
			check(main.cnc_inspector.is_visible_in_tree() == (room == "cnc"), "CNC panel room visibility")
			if room == "cnc":
				check(main.cnc_inspector.get_parent() == layout.scene_info, "CNC below hall information")
				check(main.cnc_inspector.get_index() == layout.scene_info.get_child_count() - 1, "CNC follows milestone")
				check(absf(main.cnc_inspector.size.x - layout.scene_info.size.x) < 1, "CNC fills width")
			else:
				if room == "warehouse":
					modal.open_bin("goods")
				else:
					modal.open_washer()
				await settle()
				check(modal.panel.get_global_rect().end.x <= root.size.x and modal.panel.get_global_rect().end.y <= root.size.y, "Modal fits: " + room)
			if room == "cnc":
				layout.scroll.scroll_vertical = int(main.cnc_inspector.position.y + layout.scene_info.position.y + layout.workshop.position.y)
				await settle()
			await shot(room + "-" + str(viewport_size.x))
	gm.change_room("office")
	check(not modal.visible and not main.cnc_inspector.is_visible_in_tree(), "Office hides all inspectors")
