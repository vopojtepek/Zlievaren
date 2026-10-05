extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for i in range(12):
		await process_frame

func run() -> void:
	var game = root.get_node("GameManager")
	var clock = root.get_node("SimulationClock")
	root.get_node("SaveManager").set_process(false)
	clock.is_paused = true
	game.state = FoundryEngine.fresh()
	var main = load("res://src/scenes/Main.tscn").instantiate()
	root.add_child(main)
	var layout = get_first_node_in_group("responsive_ui")
	var panel = layout.warehouse_market
	var market = panel.get_child(0)
	var mode = root.get_node("DisplayMode")
	for dimensions in [Vector2i(360, 800), Vector2i(390, 844), Vector2i(844, 390), Vector2i(1920, 1080)]:
		root.size = dimensions
		mode.set_mobile(dimensions.x < 850, false)
		game.change_room("warehouse")
		await settle()
		assert(panel.is_visible_in_tree())
		assert(panel.get_index() == layout.goal_bar.get_parent().get_parent().get_parent().get_index() + 1)
		assert(panel.get_global_rect().end.x <= dimensions.x + 1)
		for category in ["raw", "goods"]:
			market._category(category)
			await settle()
			for item in market.rows:
				var button: Button = market.rows[item].button
				assert(button.icon != null)
				button.pressed.emit()
				assert(button.modulate == Color.WHITE)
				assert(button.get_global_rect().end.x <= dimensions.x + 1)
				market.quantity.value = 7
				market.quantity.get_line_edit().grab_focus()
				root.get_node("EventBus").tick_processed.emit(game.state, 0.0)
				assert(market.selected == item and market.quantity.value == 7)
				assert(market.quantity.get_line_edit().has_focus())
		assert(market.get_child(1).get_global_rect().end.x <= dimensions.x + 1)
		game.change_room("office")
		await settle()
		assert(not panel.is_visible_in_tree())
		assert(not main.management_tabs.btn_market.is_visible_in_tree())
	game.change_room("warehouse")
	clock.is_paused = false
	clock.set_process(false)
	game.state.money = 100000
	market._category("raw")
	market.quantity.value = 1
	var incoming: int = game.state.incoming.iron
	market.buy.pressed.emit()
	assert(game.state.incoming.iron == incoming + 1)
	var raw: int = game.state.raw.iron
	market.sell.pressed.emit()
	assert(game.state.incoming.iron == incoming)
	assert(game.state.raw.iron == raw)
	game.state.goods.clean_iron_pipe = 10
	market._category("goods")
	market.rows["goods:clean_iron_pipe"].button.pressed.emit()
	market.quantity.value = 2
	market.sell.pressed.emit()
	assert(game.state.goods.clean_iron_pipe == 8)
	market.minimum.value = 100000
	market.limit.pressed.emit()
	assert(game.state.limits.size() == 1)
	market.orders.get_child(0).get_child(1).pressed.emit()
	assert(game.state.limits.is_empty())
	clock.is_paused = true
	root.get_node("EventBus").pause_toggled.emit(true)
	assert(market.sell.disabled and market.limit.disabled)
	print("OK warehouse market: placement, icons, mobile fit, persistent inputs, buy/sell/limit/cancel and pause")
	main.free()
	quit()
