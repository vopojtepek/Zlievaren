class_name MachineInspector
extends PanelContainer

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var kind_label: Label = $VBox/Header/KindLabel
@onready var status_badge: Label = $VBox/Header/StatusBadge

@onready var operator_box: PanelContainer = $VBox/OperatorBox
@onready var operator_name: Label = $VBox/OperatorBox/VBox/OperatorName
@onready var btn_goto_office: Button = $VBox/OperatorBox/VBox/BtnGotoOffice

@onready var owned_controls: VBoxContainer = $VBox/OwnedControls
@onready var purchase_controls: VBoxContainer = $VBox/PurchaseControls
@onready var btn_buy_machine: Button = $VBox/PurchaseControls/BtnBuyMachine

@onready var product_icon: TextureRect = $VBox/OwnedControls/ProductBox/ProductHBox/ProductIcon
@onready var product_select: OptionButton = $VBox/OwnedControls/ProductBox/ProductHBox/ProductSelect
@onready var dimensions_label: Label = $VBox/OwnedControls/ProductBox/DimensionsLabel
@onready var recipe_label: Label = $VBox/OwnedControls/ProductBox/RecipeLabel
@onready var quality_label: Label = $VBox/OwnedControls/ProductBox/QualityLabel

@onready var temp_label: Label = $VBox/OwnedControls/TempBox/HBox/TempLabel
@onready var temp_bar: ProgressBar = $VBox/OwnedControls/TempBox/TempBar

@onready var cycle_label: Label = $VBox/OwnedControls/CycleBox/CycleLabel
@onready var cycle_bar: ProgressBar = $VBox/OwnedControls/CycleBox/CycleBar

@onready var check_auto: CheckBox = $VBox/OwnedControls/ActionBox/CheckAuto
@onready var btn_action: Button = $VBox/OwnedControls/ActionBox/BtnAction
@onready var btn_upgrade: Button = $VBox/OwnedControls/ActionBox/BtnUpgrade
@onready var hint_label: Label = $VBox/OwnedControls/HintLabel

var slot: int = 0
var available_product_ids: Array = ["iron_pipe", "ring", "steel_pipe", "bronze_bushing"]
var machine_tabs: Array[Button] = []

func _ready() -> void:
	var tabs = BoxContainer.new()
	tabs.set_meta("keep_horizontal", true)
	$VBox.add_child(tabs)
	$VBox.move_child(tabs, 0)
	for i in range(Constants.SLOTS):
		var b = Button.new()
		b.text = str(i + 1)
		b.toggle_mode = true
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 32
		var selected_style = StyleBoxFlat.new()
		selected_style.bg_color = Color("#c0d6c5")
		selected_style.set_corner_radius_all(4)
		selected_style.set_content_margin_all(6)
		b.add_theme_stylebox_override("pressed", selected_style)
		b.add_theme_color_override("font_pressed_color", Color("#183c32"))
		b.pressed.connect(func(): GameManager.select_machine(i))
		tabs.add_child(b)
		machine_tabs.append(b)
	var preview = Control.new()
	preview.custom_minimum_size.y = 185
	preview.clip_contents = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$VBox.add_child(preview)
	$VBox.move_child(preview, 2)
	var drawing = preload("res://src/ui/inspectors/MachinePreview.gd").new()
	preview.add_child(drawing)
	preview.resized.connect(func(): drawing.position.x = (preview.size.x - 320.0) / 2.0)
	title_label.add_theme_font_override("font", preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
	title_label.add_theme_font_size_override("font_size", 28)
	product_select.fit_to_longest_item = false
	operator_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	EventBus.tick_processed.connect(_on_tick)
	EventBus.pause_toggled.connect(func(_paused): _update_view())
	EventBus.machine_selected.connect(_on_machine_selected)
	
	btn_goto_office.pressed.connect(func(): GameManager.change_room("office"))
	btn_buy_machine.pressed.connect(_on_buy_machine)
	btn_action.pressed.connect(_on_action_pressed)
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	check_auto.toggled.connect(_on_auto_toggled)
	product_select.item_selected.connect(_on_product_selected)
	
	_populate_products()
	_update_view()

func _populate_products() -> void:
	product_select.clear()
	for i in range(available_product_ids.size()):
		var id = available_product_ids[i]
		var p = Constants.PRODUCTS[id]
		var icon_path = "res://assets/textures/products/%s.svg" % id
		if ResourceLoader.exists(icon_path):
			product_select.add_icon_item(load(icon_path), p.name, i)
		else:
			product_select.add_item(p.name, i)

func _on_machine_selected(new_slot: int) -> void:
	slot = new_slot
	_update_view()

func _on_product_selected(index: int) -> void:
	if index >= 0 and index < available_product_ids.size():
		var prod_id = available_product_ids[index]
		GameManager.execute({ "type": "machine", "slot": slot, "action": "configure", "product": prod_id })

func _on_buy_machine() -> void:
	GameManager.execute({ "type": "machine", "slot": slot, "action": "buy" })

func _on_action_pressed() -> void:
	var state = GameManager.state
	if state == null or state.is_empty():
		return
	var m = state.machines[slot]
	if m == null:
		return
	if m.state == "ready":
		GameManager.execute({ "type": "machine", "slot": slot, "action": "collect" })
	elif m.state == "idle":
		GameManager.execute({ "type": "machine", "slot": slot, "action": "cast" })

func _on_auto_toggled(toggled_on: bool) -> void:
	GameManager.execute({ "type": "machine", "slot": slot, "action": "auto", "enabled": toggled_on })

func _on_upgrade_pressed() -> void:
	GameManager.execute({ "type": "machine", "slot": slot, "action": "upgrade" })

func _on_tick(_state: Dictionary, _delta: float) -> void:
	_update_view()

func _update_view() -> void:
	var state = GameManager.state
	if state == null or state.is_empty():
		return
	
	title_label.text = "Stanovište %02d" % (slot + 1)
	for i in range(machine_tabs.size()):
		machine_tabs[i].set_pressed_no_signal(i == slot)
	var m = state.machines[slot]
	
	if m == null:
		kind_label.text = "ROZŠÍRENIE VÝROBY"
		status_badge.text = "Voľné miesto"
		status_badge.modulate = Color(0.6, 0.7, 0.7)
		owned_controls.visible = false
		purchase_controls.visible = true
		operator_box.visible = false
		var price = FoundryEngine.price(state)
		btn_buy_machine.text = "Kúpiť odstredivku · %s" % Format.cash(price)
		btn_buy_machine.disabled = SimulationClock.is_paused or state.money < price
		return
	
	owned_controls.visible = true
	purchase_controls.visible = false
	operator_box.visible = true
	
	var stage = FoundryEngine.stage(m)
	var stage_name = Constants.STAGES.get(stage, stage)
	status_badge.text = stage_name
	
	var levels = ["MK I", "MK II", "MK III"]
	kind_label.text = "ODSTREDIVKA · %s" % levels[m.level - 1]
	
	# Operator info
	var op = FoundryEngine.duty(state, "operator", slot)
	if op != null:
		operator_name.text = "Obsluha: %s · %s / smena" % [op.name, Format.cash(FoundryEngine.regular_shift_pay(op))]
		operator_name.modulate = Color(0.8, 1.0, 0.8)
	else:
		operator_name.text = "Na aktuálnej smene chýba obsluha!"
		operator_name.modulate = Color(1.0, 0.6, 0.6)
	
	# Product selector
	var prod_idx = available_product_ids.find(m.product)
	if prod_idx != -1 and product_select.selected != prod_idx:
		product_select.selected = prod_idx
	product_select.disabled = SimulationClock.is_paused or m.state != "idle"
	
	var p = Constants.PRODUCTS[m.product]
	var icon_path = "res://assets/textures/products/%s.svg" % m.product
	if ResourceLoader.exists(icon_path):
		product_icon.texture = load(icon_path)
	dimensions_label.text = "%s · %s" % [p.code, p.size]
	
	# Recipe text
	var rec_parts = []
	for mat_id in p.recipe.keys():
		var req = p.recipe[mat_id]
		var cur = state.raw.get(mat_id, 0)
		var mat_short = Constants.MATERIALS[mat_id].short
		rec_parts.append("%s %d kg (máš %d)" % [mat_short, req, cur])
	recipe_label.text = "Vsádzka: " + ", ".join(rec_parts)
	
	# Quality / defect risk
	var total_risk = FoundryEngine.total_failure_risk(state, m, slot) * 100.0
	quality_label.text = "Riziko nepodarku: %.1f %%" % total_risk
	
	# Temperature
	var temp = FoundryEngine.temperature(m)
	temp_label.text = "%d °C" % int(temp)
	temp_bar.value = clampf((temp - 20.0) / (p.temp - 20.0) * 100.0, 0.0, 100.0)
	
	# Cycle progress
	var dur = FoundryEngine.duration(m.level, m.product)
	var el = float(m.elapsed)
	if m.state == "working":
		cycle_label.text = "Výroba: %d / %d s" % [int(el), int(dur)]
		cycle_bar.value = clampf(el / maxf(1.0, dur) * 100.0, 0.0, 100.0)
	elif m.state == "unloading":
		cycle_label.text = "Odnášanie: %d s" % int(ceil(Constants.UNLOAD_SECONDS - m.unloadElapsed))
		cycle_bar.value = clampf(float(m.unloadElapsed) / Constants.UNLOAD_SECONDS * 100.0, 0.0, 100.0)
	elif m.state == "failed":
		cycle_label.text = "Odstránenie nepodarku: %d s" % int(ceil(Constants.FAILURE_SECONDS - m.failedElapsed))
		cycle_bar.value = clampf(float(m.failedElapsed) / Constants.FAILURE_SECONDS * 100.0, 0.0, 100.0)
	elif m.state == "ready":
		cycle_label.text = "Hotový odliatok pripravený"
		cycle_bar.value = 100.0
	else:
		cycle_label.text = "Cyklus: %d s" % int(dur)
		cycle_bar.value = 0.0
		
	# Action buttons
	check_auto.set_pressed_no_signal(m.auto)
	check_auto.disabled = SimulationClock.is_paused
	
	var can_cast_reason = FoundryEngine.can_cast(state, slot) if m.state == "idle" else ""
	if m.state == "ready":
		btn_action.text = "Odniesť na paletu"
		btn_action.disabled = SimulationClock.is_paused or FoundryEngine.operator(state, slot) == null
	elif m.state == "working" or m.state == "unloading" or m.state == "failed":
		btn_action.text = stage_name
		btn_action.disabled = true
	else:
		btn_action.text = "Odliať dávku"
		btn_action.disabled = SimulationClock.is_paused or not can_cast_reason.is_empty()
	
	hint_label.text = can_cast_reason
	
	# Upgrade button
	if m.level >= 3:
		btn_upgrade.text = "MK III (maximum)"
		btn_upgrade.disabled = true
	else:
		var up_price = FoundryEngine.upgrade_price(m)
		btn_upgrade.text = "Vylepšiť na MK %s · %s" % [levels[m.level], Format.cash(up_price)]
		btn_upgrade.disabled = SimulationClock.is_paused or m.state != "idle" or state.money < up_price
