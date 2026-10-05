extends SceneTree

func _initialize() -> void:
	call_deferred("check_market")

func settle() -> void:
	for i in range(8):
		await process_frame

func check_market() -> void:
	root.get_node("SimulationClock").is_paused = true
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	root.add_child(margin)
	var market = load("res://src/ui/panels/WebMarket.gd").new()
	margin.add_child(market)
	for width in [1440, 704]:
		root.size = Vector2i(width, 1000)
		await settle()
		assert(market.vertical == (width < 898))
		assert(market.get_global_rect().end.x <= width)
		for id in Constants.MATERIALS:
			var button: Button = market.rows["raw:" + id].button
			assert(button.icon != null and button.icon.get_size() == Vector2(28, 28))
			button.pressed.emit()
			assert(market.selected == "raw:" + id)
			assert(market.ticket_title.text == Constants.MATERIALS[id].name)
			assert(button.modulate == Color.WHITE)
			assert(button.size.x >= button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x + 48)
			button.grab_focus()
			market.refresh(root.get_node("GameManager").state)
			assert(button.has_focus())
		market._category("goods")
		for row in market.rows.values():
			assert(row.button.icon != null)
			row.button.pressed.emit()
			assert(row.button.modulate == Color.WHITE)
		market._category("raw")
		assert(market.rows.size() == 5)
		await settle()
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/market-%d.png" % width)
	print("OK market: material and product icons, selection, focus, categories and readable names at 1440 / 704 px")
	margin.free()
	quit()
