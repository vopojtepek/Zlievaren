extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func settle() -> void:
	for i in range(8):
		await process_frame

func capture() -> void:
	root.get_node("SimulationClock").is_paused = true
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(scroll)
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	scroll.add_child(margin)
	var ui = preload("res://src/ui/panels/WebContracts.gd").new()
	margin.add_child(ui)
	var s = Fixtures.fresh()
	var sample: Dictionary = s.contracts[0].duplicate(true)
	s.contracts.clear()
	for status in ["offer", "active", "done", "expired", "lapsed"]:
		var c = sample.duplicate(true)
		c.id = status
		c.status = status
		c.deadline = s.clock + 135
		s.contracts.append(c)
	s.relationships[Constants.COMPANIES[0]].score = 60
	s.relationships[Constants.COMPANIES[1]].score = -15
	ui.refresh(s, false)
	for width in [1440, 800, 600]:
		root.size = Vector2i(width, 1100)
		await settle()
		assert(ui.contract_grid.columns == (3 if width > 850 else (2 if width > 620 else 1)))
		assert(ui.get_global_rect().end.x <= width)
		assert(not scroll.get_h_scroll_bar().visible)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/contracts-%d.png" % width)
		scroll.scroll_vertical = 300
		await settle()
		var offset = scroll.scroll_vertical
		var button: Button = ui.cards.offer.button
		button.grab_focus()
		await settle()
		offset = scroll.scroll_vertical
		for i in range(60):
			s.clock += 0.016
			ui.refresh(s, false)
		await settle()
		assert(ui.cards.offer.button == button and button.has_focus())
		assert(scroll.scroll_vertical == offset)
		scroll.scroll_vertical = 0
	print("CONTRACT VISUAL CHECKS: 0 failures; 1440, 800, 600 px; persistent focus and scroll")
	scroll.free()
	await process_frame
	quit()
