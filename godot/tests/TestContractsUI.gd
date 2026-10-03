extends RefCounted

func run_all(tree: SceneTree) -> bool:
	var s = Fixtures.fresh()
	var ui = preload("res://src/ui/panels/WebContracts.gd").new()
	tree.root.add_child(ui)
	ui.command_requested.connect(func(command: Dictionary):
		FoundryEngine.perform(s, command)
		ui.refresh(s, false)
	)
	ui.refresh(s, false)
	var id: String = s.contracts[0].id
	var button: Button = ui.cards[id].button
	assert(ui.active_label.text == "Aktívne 0 / 2")
	assert(ui.companies.size() == Constants.COMPANIES.size())
	for i in range(120):
		s.clock += 0.016
		ui.refresh(s, false)
	assert(ui.cards[id].button == button and not button.is_queued_for_deletion())
	button.pressed.emit()
	assert(s.contracts[0].status == "active")
	assert(ui.active_label.text == "Aktívne 1 / 2")
	assert(button.disabled) # No free stock.
	s.goods[s.contracts[0].product] = s.contracts[0].quantity
	ui.refresh(s, false)
	assert(not button.disabled)
	ui.refresh(s, true)
	assert(button.disabled)
	ui.refresh(s, false)
	button.pressed.emit()
	assert(s.contracts[0].status == "done")
	assert(ui.cards[id].status.text == "Splnená" and button.disabled)
	s.goods[s.contracts[0].product] = s.contracts[0].quantity
	for status in ["offer", "active", "done", "expired", "lapsed"]:
		var c = s.contracts[0]
		c.status = status
		c.deadline = s.clock + 135
		ui.refresh(s, false)
		assert(ui.cards.has(id))
		assert(button.disabled == (status in ["done", "expired", "lapsed"]))
	for c in s.contracts:
		c.status = "active"
		c.deadline = s.clock + 135
	s.contracts[0].status = "offer"
	ui.refresh(s, false)
	assert(button.disabled and ui.active_label.text == "Aktívne 2 / 2")
	s.contracts[0].offerDeadline = s.clock
	s.contracts[1].status = "done"
	ui.refresh(s, false)
	assert(button.disabled)
	var buyer: String = Constants.COMPANIES[0]
	s.relationships[buyer].score = -15
	s.relationships[buyer].missed = 2
	ui.refresh(s, false)
	assert(ui.companies[buyer].score.text == "-15")
	assert(ui.companies[buyer].terms.text.contains("-4 % ceny"))
	assert(ui.companies[buyer].history.text.contains("2 zmeškaných"))
	s.contracts.clear()
	ui.refresh(s, false)
	assert(ui.cards.is_empty() and ui.contract_grid.get_child_count() == 0)
	ui.free()
	print("OK contracts UI: persistent click targets, all states, capacity, deadlines, stock, pause and company terms")
	return true
