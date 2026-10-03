class_name CncInspector
extends PanelContainer

@onready var title_label: Label = $VBox/TitleLabel
@onready var summary_label: Label = $VBox/SummaryLabel
@onready var machine_list: VBoxContainer = $VBox/MachineList

func _ready() -> void:
	EventBus.tick_processed.connect(_on_tick)
	EventBus.pause_toggled.connect(func(_paused): _update_view())
	_build_ui()
	_update_view()

func _build_ui() -> void:
	for child in machine_list.get_children():
		child.queue_free()
		
	for i in range(7):
		var row = HBoxContainer.new()
		row.name = "Row_%d" % i
		
		var name_lbl = Label.new()
		name_lbl.name = "Name"
		name_lbl.text = "AMADA" if i == 6 else "CNC %d" % (i + 1)
		name_lbl.custom_minimum_size = Vector2(48, 0)
		row.add_child(name_lbl)
		
		var status_lbl = Label.new()
		status_lbl.name = "Status"
		status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(status_lbl)
		
		var btn = Button.new()
		btn.name = "Btn"
		btn.custom_minimum_size = Vector2(100, 32)
		var slot_idx = i
		btn.pressed.connect(func(): _on_cnc_clicked(slot_idx))
		row.add_child(btn)
		
		machine_list.add_child(row)

func _on_cnc_clicked(slot_idx: int) -> void:
	var state = GameManager.state
	if state == null or state.is_empty() or slot_idx == 6:
		return
	var owned = state.cncOwned[slot_idx]
	if not owned:
		GameManager.execute({ "type": "cnc", "slot": slot_idx, "action": "buy" })
	else:
		GameManager.execute({ "type": "cnc", "slot": slot_idx, "action": "toggle" })

func _on_tick(_state: Dictionary, _delta: float) -> void:
	_update_view()

func _update_view() -> void:
	var state = GameManager.state
	if state == null or state.is_empty():
		return
		
	var owned_count = 0
	for i in range(6):
		if state.cncOwned[i]:
			owned_count += 1
	summary_label.text = "%d / 6 kúpených CNC strojov" % owned_count
	
	for i in range(7):
		var row = machine_list.get_node_or_null("Row_%d" % i)
		if row == null:
			continue
		var status_lbl = row.get_node("Status") as Label
		var btn = row.get_node("Btn") as Button
		
		var is_amada = (i == 6)
		var owned = state.cncOwned[i]
		var power = state.cncPower[i]
		
		if is_amada:
			status_lbl.text = "Zamknutá"
			status_lbl.modulate = Color(0.6, 0.6, 0.6)
			btn.text = "Zamknuté"
			btn.disabled = true
		elif not owned:
			var price = FoundryEngine.cnc_price(i)
			status_lbl.text = "Nevlastníš"
			status_lbl.modulate = Color(0.7, 0.7, 0.7)
			btn.text = "Kúpiť · %s" % Format.cash(price)
			btn.disabled = SimulationClock.is_paused or state.money < price
		else:
			if power:
				status_lbl.text = "Zapnuté"
				status_lbl.modulate = Color(0.4, 0.9, 0.6)
				btn.text = "Vypnúť"
			else:
				status_lbl.text = "Vypnuté"
				status_lbl.modulate = Color(0.9, 0.5, 0.4)
				btn.text = "Zapnúť"
			btn.disabled = SimulationClock.is_paused
