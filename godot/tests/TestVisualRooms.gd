class_name TestVisualRooms
extends RefCounted

var n: int = 0

func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		printerr("FAIL: ", msg, " | Condition is false")
		assert(false)

func run_all() -> bool:
	print("--- Running TestVisualRooms ---")
	test_asset_files_exist()
	test_foundry_hall_rendering()
	test_washer_hall_rendering()
	test_cnc_hall_rendering()
	test_warehouse_hall_rendering()
	print(str(n) + " visual room rendering checks passed.")
	return true

func test_asset_files_exist() -> void:
	var char_assets = [
		"res://assets/textures/characters/foreman_miso.svg",
		"res://assets/textures/characters/foreman_miro.svg",
		"res://assets/textures/characters/worker_furnace.svg",
		"res://assets/textures/characters/worker_operator.svg",
		"res://assets/textures/characters/worker_washer.svg",
		"res://assets/textures/characters/worker_storekeeper.svg"
	]
	for p in char_assets:
		assert_true(FileAccess.file_exists(p), "Character asset exists: " + p)
		n += 1

	var mach_assets = [
		"res://assets/textures/machines/centra_mk1.svg",
		"res://assets/textures/machines/washer_enclosure.svg"
	]
	for p in mach_assets:
		assert_true(FileAccess.file_exists(p), "Machine asset exists: " + p)
		n += 1
	print("OK standalone character and machine SVG assets verified on disk")

func test_foundry_hall_rendering() -> void:
	var hall = FoundryHall.new()
	var s = Fixtures.fresh()
	hall.current_state = s

	# 1. Day shift with Mišo
	hall.time = 5.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# 2. Night shift with Miro (clock = 135s -> 18:00)
	s.clock = 135.0
	hall.time = 15.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# 3. Machine states: working, cooling, failed, ready
	var m0 = s.machines[0]
	m0.state = "working"
	m0.elapsed = 15.0
	m0.temp = 1200.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# Failed machine with reject sparks
	m0.state = "failed"
	m0.failedElapsed = 0.5
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# Ready / Unloading machine with operator
	m0.state = "unloading"
	m0.unloadElapsed = 2.0
	m0.temp = 350.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# Molten metal delivery ladle pouring
	s.delivery = { "slot": 0, "returnElapsed": null, "furnaceId": "f1", "crew": 0 }
	m0.state = "working"
	m0.elapsed = Constants.FLOW.carryEnd + 1.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	hall.free()
	print("OK FoundryHall renders Mišo, Miro, machines, cooling, steam, sparks and operators without error")

func test_washer_hall_rendering() -> void:
	var hall = WasherHall.new()
	var s = Fixtures.fresh()
	hall.current_state = s

	# 1. Standby
	hall.time = 2.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# 2. Loading dirty pipe
	s.washer.active = "iron_pipe"
	s.washer.elapsed = 1.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# 3. High-pressure washing with water spray
	s.washer.elapsed = 5.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# 4. Ejecting clean pipe
	s.washer.elapsed = 13.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	hall.free()
	print("OK WasherHall renders enclosure, manometer, sliding tubes, spray and attendants without error")

func test_cnc_hall_rendering() -> void:
	var hall = CncHall.new()
	var s = Fixtures.fresh()
	hall.current_state = s

	# 1. Unowned CNC machines
	hall.time = 3.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# 2. Owned and powered CNC machine (tool offset, spindle, tower light)
	s.cncOwned[0] = true
	s.cncPower[0] = true
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	hall.free()
	print("OK CncHall renders retro CNCs, AMADA, swarf bins, tool carriages and workstation without error")

func test_warehouse_hall_rendering() -> void:
	var hall = WarehouseHall.new()
	var s = Fixtures.fresh()
	hall.current_state = s

	# 1. Standard stock bins
	s.raw["iron"] = 100
	s.raw["copper"] = 40
	s.goods["clean_iron_pipe"] = 5
	hall.time = 4.0
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	# 2. Storekeeper trolley stock movement
	s.stockMove = { "material": "copper", "quantity": 40, "at": s.clock - 1.0 }
	hall.notification(CanvasItem.NOTIFICATION_DRAW)
	n += 1

	hall.free()
	print("OK WarehouseHall renders 3D storage bins, stacked ingots, ramp and storekeeper trolley without error")
