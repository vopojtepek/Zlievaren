class_name TopHUD
extends PanelContainer

@onready var money_label: Label = $HBox/LeftBox/MoneyLabel
@onready var rep_label: Label = $HBox/LeftBox/RepLabel
@onready var day_label: Label = $HBox/CenterBox/TimeBox/DayLabel
@onready var clock_label: Label = $HBox/CenterBox/TimeBox/ClockLabel
@onready var shift_badge: Button = $HBox/CenterBox/TimeBox/ShiftBadge

@onready var btn_foundry: Button = $HBox/CenterBox/NavBox/BtnFoundry
@onready var btn_warehouse: Button = $HBox/CenterBox/NavBox/BtnWarehouse
@onready var btn_washer: Button = $HBox/CenterBox/NavBox/BtnWasher
@onready var btn_cnc: Button = $HBox/CenterBox/NavBox/BtnCnc
@onready var btn_office: Button = $HBox/CenterBox/NavBox/BtnOffice

@onready var btn_pause: Button = $HBox/RightBox/SpeedBox/BtnPause
@onready var btn_1x: Button = $HBox/RightBox/SpeedBox/Btn1x
@onready var btn_2x: Button = $HBox/RightBox/SpeedBox/Btn2x
@onready var btn_5x: Button = $HBox/RightBox/SpeedBox/Btn5x

@onready var raw_stock_label: Label = $HBox/RightBox/StockBox/RawStockLabel
@onready var goods_stock_label: Label = $HBox/RightBox/StockBox/GoodsStockLabel

var current_room: String = "foundry"

func _ready() -> void:
	EventBus.tick_processed.connect(_on_tick)
	EventBus.room_change_requested.connect(_on_room_changed)
	
	btn_foundry.pressed.connect(func(): GameManager.change_room("foundry"))
	btn_warehouse.pressed.connect(func(): GameManager.change_room("warehouse"))
	btn_washer.pressed.connect(func(): GameManager.change_room("washer"))
	btn_cnc.pressed.connect(func(): GameManager.change_room("cnc"))
	btn_office.pressed.connect(func(): GameManager.change_room("office"))
	
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_1x.pressed.connect(func(): _set_speed(1.0))
	btn_2x.pressed.connect(func(): _set_speed(2.0))
	btn_5x.pressed.connect(func(): _set_speed(5.0))
	
	_update_nav_buttons()
	_update_speed_buttons()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				GameManager.change_room("foundry")
			KEY_2:
				GameManager.change_room("warehouse")
			KEY_3:
				GameManager.change_room("washer")
			KEY_4:
				GameManager.change_room("cnc")
			KEY_5:
				GameManager.change_room("office")
			KEY_SPACE:
				_on_pause_pressed()

func _on_pause_pressed() -> void:
	SimulationClock.is_paused = not SimulationClock.is_paused
	EventBus.pause_toggled.emit(SimulationClock.is_paused)
	_update_speed_buttons()

func _set_speed(scale_val: float) -> void:
	SimulationClock.is_paused = false
	SimulationClock.time_scale = scale_val
	EventBus.pause_toggled.emit(false)
	_update_speed_buttons()

func _update_speed_buttons() -> void:
	var paused = SimulationClock.is_paused
	var scale_val = SimulationClock.time_scale
	btn_pause.button_pressed = paused
	btn_1x.button_pressed = (not paused and is_equal_approx(scale_val, 1.0))
	btn_2x.button_pressed = (not paused and is_equal_approx(scale_val, 2.0))
	btn_5x.button_pressed = (not paused and is_equal_approx(scale_val, 5.0))

func _on_room_changed(room_name: String) -> void:
	current_room = room_name
	_update_nav_buttons()

func _update_nav_buttons() -> void:
	btn_foundry.button_pressed = (current_room == "foundry")
	btn_warehouse.button_pressed = (current_room == "warehouse")
	btn_washer.button_pressed = (current_room == "washer")
	btn_cnc.button_pressed = (current_room == "cnc")
	btn_office.button_pressed = (current_room == "office")

func _on_tick(state: Dictionary, _delta: float) -> void:
	if state == null or state.is_empty():
		return
	
	money_label.text = Format.cash(state.money)
	rep_label.text = "⭐ %d" % state.get("reputation", 0)
	
	var day_num = FoundryEngine.day(state)
	day_label.text = "Deň %d" % day_num
	clock_label.text = Format.clock_time(state.clock)
	
	var shift_idx = FoundryEngine.shift(state)
	var crew_info = Constants.CREWS[shift_idx]
	shift_badge.text = "%s (%s)" % [crew_info.shift, crew_info.name]
	
	# Missing staff indicator in office button
	var pos_list = FoundryEngine.positions(state)
	var missing_count: int = 0
	for p in pos_list:
		if FoundryEngine.position_active(state, p) and FoundryEngine.duty(state, p.role, p.slot) == null:
			missing_count += 1
	if missing_count > 0:
		btn_office.text = "[5] Kancelária (%d !)" % missing_count
		btn_office.modulate = Color(1.0, 0.7, 0.4)
	else:
		btn_office.text = "[5] Kancelária"
		btn_office.modulate = Color.WHITE
		
	# Quick stock preview
	var raw = state.raw
	raw_stock_label.text = "Fe: %d | Oceľ: %d | Meď: %d | Cín: %d | Zn: %d" % [
		raw.get("iron", 0),
		raw.get("steel", 0),
		raw.get("copper", 0),
		raw.get("tin", 0),
		raw.get("zinc", 0)
	]
	var goods_used = FoundryEngine.used(state, "goods")
	var goods_cap = FoundryEngine.capacity(state, "goods")
	goods_stock_label.text = "Sklad výrobkov: %d / %d ks" % [goods_used, goods_cap]
