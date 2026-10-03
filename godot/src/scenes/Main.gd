extends Node2D

@onready var top_hud: TopHUD = $UI/TopHUD
@onready var office_view: OfficeView = $UI/OfficeView
@onready var toast_manager: ToastManager = $UI/ToastManager
@onready var management_tabs: ManagementTabs = $UI/ManagementTabs

# Inspectors
@onready var inspectors_container: Control = $UI/Inspectors
@onready var machine_inspector: MachineInspector = $UI/Inspectors/MachineInspector
@onready var warehouse_inspector: WarehouseInspector = $UI/Inspectors/WarehouseInspector
@onready var washer_inspector: WasherInspector = $UI/Inspectors/WasherInspector
@onready var cnc_inspector: CncInspector = $UI/Inspectors/CncInspector

# 2D Rooms
@onready var room_container: Node2D = $World2D/RoomContainer
@onready var foundry_hall: FoundryHall = $World2D/RoomContainer/FoundryHall
@onready var warehouse_hall: WarehouseHall = $World2D/RoomContainer/WarehouseHall
@onready var washer_hall: WasherHall = $World2D/RoomContainer/WasherHall
@onready var cnc_hall: CncHall = $World2D/RoomContainer/CncHall

func _ready() -> void:
	print("Žeravá zlievareň — Main scene ready.")
	EventBus.room_change_requested.connect(_on_room_changed)
	
	# Try load save or start fresh
	if SaveManager.has_saved_game():
		var ok = SaveManager.load_game()
		if not ok:
			GameManager.new_game()
	elif GameManager.state == null or GameManager.state.is_empty():
		GameManager.new_game()
		
	_on_room_changed(GameManager.current_room)

func _on_room_changed(room_name: String) -> void:
	var is_office = (room_name == "office")
	office_view.visible = is_office
	room_container.visible = not is_office
	inspectors_container.visible = not is_office
	management_tabs.visible = not is_office
	
	if not is_office:
		foundry_hall.visible = (room_name == "foundry")
		warehouse_hall.visible = (room_name == "warehouse")
		washer_hall.visible = (room_name == "washer")
		cnc_hall.visible = (room_name == "cnc")
		
		machine_inspector.visible = (room_name == "foundry")
		warehouse_inspector.visible = (room_name == "warehouse")
		washer_inspector.visible = (room_name == "washer")
		cnc_inspector.visible = (room_name == "cnc")
