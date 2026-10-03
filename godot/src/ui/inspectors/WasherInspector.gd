class_name WasherInspector
extends PanelContainer

@onready var title_label: Label = $VBox/TitleLabel
@onready var status_label: Label = $VBox/StatusLabel
@onready var operator_label: Label = $VBox/OperatorLabel
@onready var progress_bar: ProgressBar = $VBox/ProgressBar

@onready var product_select: OptionButton = $VBox/ProductBox/ProductSelect
@onready var input_stock_label: Label = $VBox/ProductBox/InputStockLabel
@onready var output_stock_label: Label = $VBox/ProductBox/OutputStockLabel

@onready var check_auto: CheckBox = $VBox/CheckAuto
@onready var btn_start: Button = $VBox/BtnStart
@onready var total_label: Label = $VBox/TotalLabel
@onready var hint_label: Label = $VBox/HintLabel

var wash_products = ["iron_pipe", "ring", "steel_pipe", "bronze_bushing"]

func _ready() -> void:
	EventBus.tick_processed.connect(_on_tick)
	EventBus.pause_toggled.connect(func(_paused): _update_view())
	btn_start.pressed.connect(_on_start_pressed)
	check_auto.toggled.connect(_on_auto_toggled)
	product_select.item_selected.connect(_on_product_selected)
	
	_populate_products()
	_update_view()

func _populate_products() -> void:
	product_select.clear()
	for i in range(wash_products.size()):
		var id = wash_products[i]
		var p = Constants.PRODUCTS[id]
		var out_id = Constants.WASH.outputs[id]
		var out_p = Constants.PRODUCTS[out_id]
		product_select.add_item(p.name, i)

func _on_product_selected(index: int) -> void:
	if index >= 0 and index < wash_products.size():
		var prod_id = wash_products[index]
		GameManager.execute({ "type": "washer", "action": "configure", "product": prod_id })

func _on_start_pressed() -> void:
	GameManager.execute({ "type": "washer", "action": "start" })

func _on_auto_toggled(toggled_on: bool) -> void:
	GameManager.execute({ "type": "washer", "action": "auto", "enabled": toggled_on })

func _on_tick(_state: Dictionary, _delta: float) -> void:
	_update_view()

func _update_view() -> void:
	var state = GameManager.state
	if state == null or state.is_empty():
		return
	
	var w = state.washer
	var stage = FoundryEngine.wash_stage(state)
	var reason = FoundryEngine.can_wash(state)
	
	var op = FoundryEngine.duty(state, "washer")
	if op != null:
		operator_label.text = "Obsluha: %s · %s / smena" % [op.name, Format.cash(FoundryEngine.regular_shift_pay(op))]
		operator_label.modulate = Color(0.8, 1.0, 0.8)
	else:
		operator_label.text = "Chýba obsluha pieskovača na aktuálnej smene!"
		operator_label.modulate = Color(1.0, 0.6, 0.6)
		
	var stage_texts = {
		"idle": "Pripravený na výrobok",
		"loading": "Nakladanie sprava",
		"washing": "Vodné čistenie v komore",
		"ejecting": "Vysúvanie očisteného výrobku"
	}
	status_label.text = stage_texts.get(stage, stage)
	
	if w.active != null:
		progress_bar.max_value = Constants.WASH.total
		progress_bar.value = float(w.elapsed)
		btn_start.text = "Prebieha čistenie (%d s)" % int(ceil(Constants.WASH.total - w.elapsed))
		btn_start.disabled = true
	else:
		progress_bar.value = 0.0
		btn_start.text = "Naložiť a vyčistiť · %s" % Format.cash(Constants.WASH.cost)
		btn_start.disabled = SimulationClock.is_paused or not reason.is_empty()
		
	var cur_idx = wash_products.find(w.product)
	if cur_idx != -1 and product_select.selected != cur_idx:
		product_select.selected = cur_idx
	product_select.disabled = SimulationClock.is_paused or w.active != null
	
	var out_id = Constants.WASH.outputs.get(w.product, "")
	var avail_in = FoundryEngine.available(state, w.product)
	var cur_out = state.goods.get(out_id, 0)
	input_stock_label.text = "Voľné odliatky v sklade: %d ks" % avail_in
	output_stock_label.text = "Očistené výrobky v sklade: %d ks" % cur_out
	
	check_auto.set_pressed_no_signal(w.auto)
	check_auto.disabled = SimulationClock.is_paused
	
	total_label.text = "Očistených celkom: %d ks" % w.cleaned
	hint_label.text = reason
