extends "res://src/rooms/FoundryHall.gd"

func _ready() -> void:
	super._ready()
	set_process_input(false)
	EventBus.machine_selected.connect(func(_i): queue_redraw())

func _draw() -> void:
	var state = get_room_state()
	if state.is_empty():
		return
	var slot = int(state.selected)
	var m = state.machines[slot]
	if m == null:
		m = FoundryEngine.machine()
	draw_machine(Vector2(155, 170), m, slot, false, state, true)
