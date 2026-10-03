extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func settle() -> void:
	for i in range(12): await process_frame

func run() -> void:
	root.get_node("SimulationClock").is_paused = true
	var state = FoundryEngine.fresh()
	var key = "operator:0:0"
	var candidates: Array = state.hr.candidates[key]
	while candidates.size() < 5:
		var extra = candidates[0].duplicate(true)
		extra.id = "portrait-test-" + str(candidates.size())
		extra.name = "Alexander Maximilián Dlhé Priezvisko " + str(candidates.size())
		candidates.append(extra)
	var office = load("res://src/ui/office/OfficeView.tscn").instantiate()
	office.current_state = state
	office.custom_minimum_size.x = 0
	root.add_child(office)
	office.recruit_position_key = key
	office._switch_tab("hire")
	await settle()
	var grid = office.recruit_shifts_list.get_child(0).get_child(1)
	var identity = grid.get_child(0).portrait.identity
	var candidate: Dictionary = candidates[0].duplicate(true)
	FoundryEngine.perform(state, {"type": "personnel", "action": "hire", "position": key, "candidateId": candidate.id})
	office._switch_tab("overview")
	await settle()
	var hired_card = office.employees_list.get_child(office.employees_list.get_child_count() - 1)
	check(hired_card.portrait.identity == identity, "Portrait survives hiring")
	var restored = JSON.parse_string(JSON.stringify(state))
	office.current_state = restored
	office._update_view(true)
	await settle()
	hired_card = office.employees_list.get_child(office.employees_list.get_child_count() - 1)
	check(hired_card.portrait.identity == identity, "Portrait survives serialization and recreation")
	# Restore the five-person candidate group for wrapping checks.
	office.current_state = state
	state.hr.employees.pop_back()
	state.hr.candidates[key] = candidates
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	for width in [1440, 800]:
		root.size = Vector2i(width, 1000)
		for tab in ["overview", "hire"]:
			office._switch_tab(tab)
			await settle()
			for card_grid in get_nodes_in_group("personnel_grids"):
				if not card_grid.is_visible_in_tree(): continue
				check(card_grid.get_global_rect().end.x <= width, "Grid fits %d / %s" % [width, tab])
				for card in card_grid.get_children():
					check(card.action_button.disabled, "Paused card action disabled")
					check(card.get_global_rect().end.x <= width, "Card fits viewport")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/personnel-%s-%d.png" % [tab, width])
	print("PERSONNEL CHECKS: %d failures" % failures)
	office.queue_free()
	await settle()
	quit(1 if failures else 0)
