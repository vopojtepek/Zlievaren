extends SceneTree
var main: Node
var tutorial: Node
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in range(32): await process_frame
func capture(label_text: String) -> void:
	await settle()
	print(label_text, " card=", tutorial.card.get_global_rect(), " hole=", tutorial.hole, " target=", tutorial.target)
	assert(not tutorial.card.get_global_rect().intersects(tutorial.hole), "Explanation overlaps target")
	assert(tutorial.target == null or tutorial.hole.has_area(), "Target is off screen")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/tutorial-" + label_text + ".png")
func run() -> void:
	root.size = Vector2i(1440, 1000)
	root.get_node("SimulationClock").set_physics_process(false)
	root.get_node("SaveManager").set_process(false)
	root.get_node("DisplayMode").settings_path = "user://tutorial-test-display.cfg"
	root.get_node("DisplayMode").set_mobile(false, false)
	main = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await settle()
	for child in main.get_node("UI").get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("TutorialController.gd"): tutorial = child
	for width in [1440, 390]:
		root.size = Vector2i(width, 1000 if width == 1440 else 844)
		root.get_node("DisplayMode").set_mobile(width == 390, false)
		root.get_node("GameManager").new_game()
		await capture("welcome-%d" % width)
		tutorial.advance(3)
		await settle()
		tutorial.advance(4)
		await capture("hire-%d" % width)
		# Populate workers through the engine to inspect later stages independently.
		var state: Dictionary = root.get_node("GameManager").state
		for role in tutorial.ROLES:
			var key: String = tutorial.role_key(role)
			FoundryEngine.perform(state, {"type": "personnel", "action": "hire", "position": key, "candidateId": state.hr.candidates[key][0].id})
		tutorial.advance(6)
		await capture("market-%d" % width)
		state.incoming.zinc = 1
		tutorial.advance(10)
		await capture("store-%d" % width)
		tutorial.advance(15)
		await capture("cast-%d" % width)
	tutorial.finish("skipped")
	main.free()
	quit()
