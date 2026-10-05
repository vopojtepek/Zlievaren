extends Node

signal command_finished(command: Dictionary, result: Dictionary)
signal game_started
var tutorial_command_filter: Callable

var state: Dictionary = {}
var current_room: String = "foundry"
var selected_machine: int = 0
var selected_bin: String = "iron"

func _ready() -> void:
	new_game()

func new_game() -> void:
	state = FoundryEngine.fresh()
	state.tutorial = {"version": 1, "status": "active", "step": 0, "resume": -1, "role": ""}
	game_started.emit()
	current_room = "foundry"
	selected_machine = 0
	selected_bin = "iron"
	EventBus.room_change_requested.emit(current_room)
	EventBus.machine_selected.emit(selected_machine)
	EventBus.bin_selected.emit(selected_bin)

func execute(command: Dictionary) -> Dictionary:
	var clock = get_node_or_null("/root/SimulationClock")
	if clock != null and clock.get("is_paused") == true:
		var fail_res = FoundryEngine.fail_res("Najprv pokračuj v hre.")
		var eb = get_node_or_null("/root/EventBus")
		if eb != null:
			eb.toast_requested.emit(fail_res.message, true)
		command_finished.emit(command, fail_res)
		return fail_res
	if tutorial_command_filter.is_valid() and not tutorial_command_filter.call(command):
		var blocked = FoundryEngine.fail_res("Dokonči zvýraznený krok tutoriálu alebo tutoriál preskoč.")
		EventBus.toast_requested.emit(blocked.message, true)
		command_finished.emit(command, blocked)
		return blocked
	var res = FoundryEngine.perform(state, command)
	command_finished.emit(command, res)
	var eb = get_node_or_null("/root/EventBus")
	if eb != null:
		eb.toast_requested.emit(res.message, not res.ok)
	var sm = get_node_or_null("/root/SaveManager")
	if sm != null:
		sm.request_autosave()
	return res

func change_room(room_name: String) -> void:
	current_room = room_name
	EventBus.room_change_requested.emit(room_name)

func select_machine(slot: int) -> void:
	if slot >= 0 and slot < Constants.SLOTS:
		selected_machine = slot
		state.selected = slot
		EventBus.machine_selected.emit(slot)

func select_bin(bin_id: String) -> void:
	selected_bin = bin_id
	EventBus.bin_selected.emit(bin_id)
