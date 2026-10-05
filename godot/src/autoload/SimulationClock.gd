extends Node

var tutorial_hold: bool = false
var tutorial_active: bool = false
var is_paused: bool = false
var time_scale: float = 1.0

func _ready() -> void:
	var eb = get_node_or_null("/root/EventBus")
	if eb != null:
		eb.pause_toggled.connect(_on_pause_toggled)

func _physics_process(delta: float) -> void:
	if is_paused or tutorial_hold:
		return
	var gm = get_node_or_null("/root/GameManager")
	if gm == null:
		return
	var gm_state = gm.get("state")
	if gm_state == null or not (gm_state is Dictionary) or gm_state.is_empty():
		return
	var dt: float = delta * time_scale
	var ready_machines: Array = FoundryEngine.tick(gm_state, dt)
	var eb = get_node_or_null("/root/EventBus")
	if eb != null:
		eb.tick_processed.emit(gm_state, dt)
		for slot: int in ready_machines:
			var m = gm_state.machines[slot]
			eb.batch_finished.emit(slot, m.product)

func _on_pause_toggled(paused_val: bool) -> void:
	is_paused = paused_val
