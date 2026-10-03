class_name WarehouseInspector
extends PanelContainer

@onready var icon_rect: TextureRect = $VBox/Header/IconRect
@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var capacity_label: Label = $VBox/CapacityLabel
@onready var fill_bar: ProgressBar = $VBox/FillBar
@onready var ramp_label: Label = $VBox/RampLabel
@onready var btn_stock_move: Button = $VBox/BtnStockMove
@onready var btn_upgrade: Button = $VBox/BtnUpgrade
@onready var hint_label: Label = $VBox/HintLabel

var current_bin: String = "iron"

func _ready() -> void:
	EventBus.tick_processed.connect(_on_tick)
	EventBus.bin_selected.connect(_on_bin_selected)
	btn_stock_move.pressed.connect(_on_stock_move)
	btn_upgrade.pressed.connect(_on_upgrade)
	_update_view()

func _on_bin_selected(bin_id: String) -> void:
	current_bin = bin_id
	_update_view()

func _on_stock_move() -> void:
	var state = GameManager.state
	if state == null or state.is_empty():
		return
	var count = state.incoming.get(current_bin, 0)
	GameManager.execute({ "type": "store", "material": current_bin, "quantity": count })

func _on_upgrade() -> void:
	var state = GameManager.state
	if state == null or state.is_empty():
		return
	if current_bin == "goods":
		GameManager.execute({ "type": "expand", "kind": "goods" })
	else:
		GameManager.execute({ "type": "expandBin", "material": current_bin })

func _on_tick(_state: Dictionary, _delta: float) -> void:
	_update_view()

func _update_view() -> void:
	var state = GameManager.state
	if state == null or state.is_empty():
		return
	
	var is_goods = (current_bin == "goods")
	var unlocked = is_goods or state.binUnlocked.get(current_bin, true)
	
	if is_goods:
		title_label.text = "Sklad hotových výrobkov"
		var icon_p = "res://assets/textures/products/clean_iron_pipe.svg"
		if ResourceLoader.exists(icon_p):
			icon_rect.texture = load(icon_p)
		var used_qty = FoundryEngine.used(state, "goods")
		var cap_qty = FoundryEngine.capacity(state, "goods")
		capacity_label.text = "Uskladnené: %d / %d ks" % [used_qty, cap_qty]
		fill_bar.value = clampf(float(used_qty) / maxf(1.0, float(cap_qty)) * 100.0, 0.0, 100.0)
		ramp_label.visible = false
		btn_stock_move.visible = false
		
		var price = 220 * (int(state.storage.goods) + 1)
		btn_upgrade.text = "Rozšíriť sklad výrobkov (+24 ks) · %s" % Format.cash(price)
		btn_upgrade.disabled = SimulationClock.is_paused or state.money < price
		hint_label.text = "Kapacita pre liatinové rúry, oceľové prstence a čisté výrobky."
	else:
		var mat = Constants.MATERIALS.get(current_bin, {})
		title_label.text = "Zásobník: %s" % mat.get("name", current_bin)
		var mat_icon = "res://assets/textures/materials/%s.svg" % current_bin
		if ResourceLoader.exists(mat_icon):
			icon_rect.texture = load(mat_icon)
		
		if not unlocked:
			var unl_price = Constants.BIN_UNLOCK.get(current_bin, 0)
			capacity_label.text = "Zásobník je zamknutý"
			fill_bar.value = 0.0
			ramp_label.visible = false
			btn_stock_move.visible = false
			btn_upgrade.text = "Odomknúť zásobník · %s" % Format.cash(unl_price)
			btn_upgrade.disabled = SimulationClock.is_paused or state.money < unl_price
			hint_label.text = "Odomknutím získaš základnú kapacitu zásobníka."
			return
			
		var count = state.raw.get(current_bin, 0)
		var cap = FoundryEngine.bin_capacity(state, current_bin)
		capacity_label.text = "Zásoba: %d / %d kg" % [count, cap]
		fill_bar.value = clampf(float(count) / maxf(1.0, float(cap)) * 100.0, 0.0, 100.0)
		
		var incoming_count = state.incoming.get(current_bin, 0)
		ramp_label.visible = true
		ramp_label.text = "Na príjmovej rampe: %d kg" % incoming_count
		
		btn_stock_move.visible = true
		btn_stock_move.text = "Uskladniť z rampy (%d kg)" % incoming_count
		btn_stock_move.disabled = SimulationClock.is_paused or incoming_count == 0 or count >= cap
		
		var price = FoundryEngine.bin_upgrade_price(state, current_bin)
		btn_upgrade.text = "Rozšíriť kapacitu (+20 kg) · %s" % Format.cash(price)
		btn_upgrade.disabled = SimulationClock.is_paused or state.money < price
		hint_label.text = "Suroviny na rampe sa po uskladnení dajú použiť na tavenie."
