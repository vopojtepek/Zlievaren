class_name WasherHall
extends "res://src/rooms/RoomRenderer.gd"

var time: float = 0.0

func _ready() -> void:
	var eb = get_node_or_null("/root/EventBus")
	if eb != null:
		eb.tick_processed.connect(_on_tick)

func _on_tick(_state: Dictionary, delta: float) -> void:
	time += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_local_mouse_position()
		# Click on central washing unit
		var washer_rect = Rect2(372, 231, 318, 221)
		if washer_rect.has_point(mouse_pos):
			var gm = get_node_or_null("/root/GameManager")
			if gm != null and gm.state.washer.active == null:
				gm.execute({ "type": "washer", "action": "start" })

func _draw() -> void:
	var state = get_room_state()
	if state == null or state.is_empty():
		return

	var w = state.washer
	var stage = FoundryEngine.wash_stage(state)
	var running = FoundryEngine.washer_running(state)
	var t = float(w.elapsed)
	var daylight = FoundryEngine.daylight(state)
	var night = 1.0 - daylight

	# Background gradient
	draw_gradient_rect(Rect2(0, 0, 1100, 690), PackedColorArray([Color("#243b4b"), Color("#324c58"), Color("#647172"), Color("#35494e")]), PackedFloat32Array([0, 0.28, 0.281, 1]))

	# Wall columns and windows
	for x in range(25, 1100, 180):
		draw_rect(Rect2(x, 0, 10, 193), Color8(28, 48, 61))
		draw_round_rect(Rect2(x + 27, 46, 116, 83), Color8(22, 46, 62), 3)
		var win_col = Color8(132, 163, 171) if daylight > 0.4 else Color8(35, 55, 81)
		draw_rect(Rect2(x + 32, 51, 106, 73), win_col)
		draw_line(Vector2(x + 85, 51), Vector2(x + 85, 124), Color8(53, 81, 93), 5)
		draw_line(Vector2(x + 32, 88), Vector2(x + 138, 88), Color8(53, 81, 93), 4)

	draw_rect(Rect2(0, 188, 1100, 9), Color8(22, 47, 59))
	draw_pipe(0, 155, 1100, 8)
	draw_line(Vector2(0, 173), Vector2(1100, 173), Color8(175, 155, 105), 3)

	for y in range(228, 690, 62):
		draw_line(Vector2(0, y), Vector2(1100, y), Color(0.69, 0.76, 0.72, 0.09))
	for x in range(0, 1100, 110):
		draw_line(Vector2(x, 197), Vector2(x - 90, 690), Color(0.69, 0.76, 0.72, 0.08))

	# L-shaped Hall Road
	var road_pts = PackedVector2Array([
		Vector2(0, 552), Vector2(976, 552), Vector2(976, 197),
		Vector2(1100, 197), Vector2(1100, 690), Vector2(0, 690)
	])
	draw_poly(road_pts, Color8(40, 59, 67))
	draw_line(Vector2(0, 550), Vector2(974, 550), Color8(212, 184, 117), 3)
	draw_line(Vector2(974, 550), Vector2(974, 197), Color8(212, 184, 117), 3)
	draw_dash_line(Vector2(0, 614), Vector2(1043, 614), Color(0.75, 0.74, 0.61, 0.33), 3.0, 28.0, 24.0)
	draw_dash_line(Vector2(1043, 614), Vector2(1043, 197), Color(0.75, 0.74, 0.61, 0.33), 3.0, 28.0, 24.0)
	draw_canvas_text("HALOVÁ CESTA", Vector2(822, 665), Color8(139, 155, 158), 12, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Direction Arrow on road
	var arrow_pts = PackedVector2Array([
		Vector2(906, 582), Vector2(887, 573), Vector2(887, 579),
		Vector2(858, 579), Vector2(858, 585), Vector2(887, 585), Vector2(887, 591)
	])
	draw_poly(arrow_pts, Color(0.74, 0.78, 0.71, 0.3))

	# Machine Shadows
	draw_oval(Vector2(512, 471), 255, 42, Color(0.06, 0.13, 0.17, 0.33))
	draw_oval(Vector2(261, 492), 143, 20, Color(0.09, 0.17, 0.20, 0.33))
	draw_oval(Vector2(852, 479), 97, 22, Color(0.09, 0.17, 0.20, 0.33))

	# Conveyor Rails (left and right)
	draw_conveyor_rail(100, 383, 370, 0.045)
	draw_conveyor_rail(700, 943, 363, -0.035)
	draw_round_rect(Rect2(95, 353, 8, 58), Color8(181, 199, 201), 2)

	# Pipes moving through chamber
	if stage == "loading":
		var q = clampf(t / Constants.WASH.load, 0.0, 1.0)
		draw_pipe_tube(Vector2(824.0 - 280.0 * q, 359), false, w, state)
	elif stage == "ejecting":
		var q = clampf((t - Constants.WASH.washEnd) / (Constants.WASH.total - Constants.WASH.washEnd), 0.0, 1.0)
		draw_pipe_tube(Vector2(430.0 - 266.0 * q, 362.0 + q * q * 18.0), true, w, state)
	var recently_done = (not running and w.lastProduct != null and (state.clock - float(w.lastAt)) < 3.0)
	if recently_done:
		draw_pipe_tube(Vector2(164, 380), true, w, state)

	# Closed Enclosure: 3D Roof, Right Wall, Front Face
	var roof_pts = PackedVector2Array([
		Vector2(372, 231), Vector2(406, 202), Vector2(724, 202), Vector2(690, 231)
	])
	draw_poly(roof_pts, Color8(75, 141, 168), Color8(146, 185, 201), 1.0)

	var right_wall_pts = PackedVector2Array([
		Vector2(690, 231), Vector2(724, 202), Vector2(724, 422), Vector2(690, 452)
	])
	draw_poly(right_wall_pts, Color8(21, 78, 113), Color8(59, 118, 144), 1.0)

	draw_round_rect(Rect2(372, 231, 318, 221), Color8(40, 105, 143), 5)
	draw_line(Vector2(377, 233), Vector2(687, 233), Color8(133, 184, 204), 2)

	# Enclosure Header
	draw_round_rect(Rect2(381, 241, 300, 42), Color8(29, 72, 104), 3)
	draw_canvas_text("PIESKOVAČ", Vector2(460, 257), Color8(240, 245, 230), 22, HORIZONTAL_ALIGNMENT_CENTER, true)
	draw_canvas_text("VODNÉ ČISTENIE / UZAVRETÁ KOMORA", Vector2(490, 274), Color8(166, 203, 220), 9, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Service Doors
	draw_round_rect(Rect2(384, 294, 204, 136), Color8(35, 90, 128), 3)
	draw_round_rect(Rect2(390, 300, 192, 124), Color8(44, 113, 152), 3)
	draw_line(Vector2(487, 302), Vector2(487, 421), Color8(22, 63, 93), 3)
	for dx in [476.0, 497.0]:
		draw_round_rect(Rect2(dx, 347, 5, 24), Color8(196, 212, 211), 2)
	for dx in [395.0, 575.0]:
		for dy in [307.0, 418.0]:
			draw_circle(Vector2(dx, dy), 3, Color8(164, 185, 191))

	# Control Panel
	draw_round_rect(Rect2(604, 296, 66, 118), Color8(21, 60, 85), 4)
	draw_round_rect(Rect2(612, 305, 50, 31), Color8(12, 37, 53), 2)
	draw_canvas_text("AUTO · RUN" if running else "STANDBY", Vector2(637, 315), Color8(165, 233, 211) if running else Color8(174, 194, 199), 8)
	draw_canvas_text("120 bar" if (running and stage == "washing") else ("POSUV" if running else "0 bar"), Vector2(637, 329), Color8(195, 232, 236), 11, HORIZONTAL_ALIGNMENT_CENTER, true)

	draw_circle(Vector2(624, 351), 7, Color8(135, 212, 173) if running else Color8(79, 114, 116))
	draw_circle(Vector2(649, 351), 7, Color8(147, 47, 55))
	draw_circle(Vector2(649, 351), 4, Color8(224, 103, 85))

	# Analogue Manometer with animated needle
	draw_circle(Vector2(636, 387), 18, Color8(150, 180, 194))
	draw_circle(Vector2(636, 387), 14, Color8(226, 231, 216))
	for k in range(7):
		var a = -2.6 + float(k) * 0.65
		draw_line(Vector2(636 + cos(a) * 10.0, 387 + sin(a) * 10.0), Vector2(636 + cos(a) * 13.0, 387 + sin(a) * 13.0), Color8(71, 97, 109))
	var needle_end = Vector2(645, 379) if (running and stage == "washing") else Vector2(627, 394)
	draw_line(Vector2(636, 387), needle_end, Color8(164, 77, 66), 2)
	draw_circle(Vector2(636, 387), 2, Color8(56, 89, 107))

	# Lower Base & Filtration Tank
	draw_round_rect(Rect2(371, 436, 320, 17), Color8(20, 45, 65), 2)
	for lx in range(376, 682, 24):
		draw_poly(PackedVector2Array([Vector2(lx, 438), Vector2(lx + 10, 438), Vector2(lx + 19, 450), Vector2(lx + 9, 450)]), Color8(215, 180, 101))
	for lx in [391.0, 655.0]:
		draw_round_rect(Rect2(lx, 453, 13, 23), Color8(23, 52, 73), 2)
		draw_round_rect(Rect2(lx - 7, 474, 29, 6), Color8(157, 174, 176), 2)

	draw_round_rect(Rect2(479, 466, 141, 54), Color8(37, 73, 92), 5)
	var tank_top = PackedVector2Array([
		Vector2(479, 466), Vector2(490, 457), Vector2(630, 457), Vector2(619, 466)
	])
	draw_poly(tank_top, Color8(106, 152, 171))
	draw_round_rect(Rect2(487, 476, 8, 31), Color8(123, 194, 210), 2)
	draw_canvas_text("VODA · FILTRÁCIA", Vector2(557, 488), Color8(193, 216, 221), 10)
	draw_round_rect(Rect2(531, 503, 60, 4), Color8(19, 50, 69), 2)
	draw_circle(Vector2(642, 482), 14, Color8(57, 125, 150))
	draw_circle(Vector2(642, 482), 7, Color8(20, 47, 69))
	draw_line(Vector2(643, 467), Vector2(643, 448), Color8(122, 175, 189), 5)
	draw_line(Vector2(628, 487), Vector2(619, 487), Color8(131, 181, 191), 5)

	# High pressure water spray particles
	if running and stage == "washing":
		for i in range(86):
			var q = fmod(t * 1.35 + float(i) * 0.618, 1.0)
			var side = -1.0 if (i % 2 == 1) else 1.0
			var sx = 380.0 if side < 0 else 707.0
			var sy = 377.0 if side < 0 else 362.0
			var v = 25.0 + float(i % 11) * 7.0
			var px = sx + side * v * q
			var py = sy - 28.0 * q + 120.0 * q * q + float(i % 5) * 3.0
			var alpha = (1.0 - q) * 0.85
			draw_line(Vector2(px, py), Vector2(px - side * 2.0, py - 3.0 - q * 4.0), Color(0.72, 0.95, 0.98, alpha), 1.3)
			if i % 5 == 0:
				draw_oval(Vector2(sx + side * v, 470 if side < 0 else 458), 3 + q * 10, 1 + q * 3, Color(0.59, 0.87, 0.92, (1 - q) * 0.4))
		for i in range(13):
			var q = fmod(t * 0.85 + float(i) / 13, 1.0)
			draw_line(Vector2(397 + i * 13, 426), Vector2(397 + i * 13 + sin(i) * 3, 435 + q * 29), Color("#85cbd999"))

	# Pallets with unwashed/clean products
	draw_pallet_station(154, false, state, w)
	draw_pallet_station(795, true, state, w)

	draw_canvas_text("← VÝSTUP", Vector2(211, 329), Color8(182, 226, 212), 13, HORIZONTAL_ALIGNMENT_CENTER, true)
	draw_canvas_text("VSTUP ←", Vector2(850, 308), Color8(225, 220, 192), 13, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Attendant Worker
	var attendant = FoundryEngine.profile(FoundryEngine.duty(state, "washer"))
	if attendant != null and not attendant.is_empty():
		draw_worker(Vector2(782, 500), false, 0.0, false, -1.0, attendant, time)
		draw_canvas_text(attendant.get("name", "Obsluha"), Vector2(782, 524), Color8(227, 236, 228), 12, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Status Banner Top Center
	draw_round_rect(Rect2(392, 91, 325, 42), Color8(18, 44, 60, 220), 6)
	draw_circle(Vector2(410, 112), 4, Color8(140, 221, 190) if running else Color8(158, 178, 182))
	var stage_labels = {
		"idle": "PRIPRAVENÝ NA NAKLADANIE",
		"loading": "NAKLADANIE RÚRY",
		"washing": "ČISTENIE TLAKOVOU VODOU",
		"ejecting": "VÝSTUP OPRACOVANEJ RÚRY"
	}
	draw_canvas_text(stage_labels.get(stage, "PIESKOVAČ"), Vector2(552, 112), Color8(217, 232, 230), 13, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Patrolling Foreman (Mišo / Miro)
	draw_foreman_patrol(state)

	# Night ambient
	if night > 0.05:
		draw_rect(Rect2(0, 0, 1100, 690), Color(0.03, 0.07, 0.14, night * 0.23))
		for x in [260.0, 550.0, 850.0]:
			draw_glow(Vector2(x, 75), 125, Color8(213, 228, 214), 0.09 + night * 0.09)

func draw_conveyor_rail(start_x: float, end_x: float, y: float, slope: float) -> void:
	var px = start_x + 20.0
	while px < end_x:
		draw_round_rect(Rect2(px, y + 18.0 + (px - start_x) * slope, 8, 79), Color8(38, 62, 73), 2)
		draw_line(Vector2(px, y + 95.0 + (px - start_x) * slope), Vector2(px + 25.0, y + 95.0 + (px - start_x) * slope), Color8(158, 174, 176), 4)
		px += 70.0
	var rail_poly = PackedVector2Array([
		Vector2(start_x, y), Vector2(end_x, y + (end_x - start_x) * slope),
		Vector2(end_x, y + 23.0 + (end_x - start_x) * slope), Vector2(start_x, y + 23.0)
	])
	draw_poly(rail_poly, Color8(52, 78, 91), Color8(130, 152, 159))
	px = start_x + 7.0
	while px < end_x:
		draw_line(Vector2(px, y + 4.0 + (px - start_x) * slope), Vector2(px, y + 18.0 + (px - start_x) * slope), Color8(167, 185, 187), 8)
		draw_line(Vector2(px - 2.0, y + 5.0 + (px - start_x) * slope), Vector2(px - 2.0, y + 16.0 + (px - start_x) * slope), Color8(224, 228, 213), 2)
		px += 22.0
	draw_line(Vector2(start_x, y + 24.0), Vector2(end_x, y + 24.0 + (end_x - start_x) * slope), Color8(183, 198, 197), 3)

func draw_pipe_tube(pos: Vector2, clean: bool, w: Dictionary, state: Dictionary) -> void:
	var p_id = w.active if w.active != null else (w.lastProduct if (w.lastProduct != null and (state.clock - float(w.lastAt)) < 3.0) else w.product)
	var scale_x = 0.28 if p_id == "ring" else (0.45 if p_id == "bronze_bushing" else 1.0)
	var x = pos.x
	var y = pos.y
	var w_len = 132.0 * scale_x

	var body_col = Color8(180, 215, 222) if clean else Color8(142, 152, 148)
	draw_round_rect(Rect2(x, y - 29, w_len, 29), body_col, 3)
	draw_oval(Vector2(x + w_len, y - 14.5), 8 * scale_x, 14.5, Color8(171, 200, 208) if clean else Color8(174, 185, 174))
	draw_oval(Vector2(x + w_len, y - 14.5), 5 * scale_x, 10.0, Color8(25, 47, 58))
	draw_oval(Vector2(x, y - 14.5), 8 * scale_x, 14.5, Color8(216, 232, 230) if clean else Color8(185, 194, 182))
	draw_oval(Vector2(x, y - 14.5), 5 * scale_x, 10.0, Color8(36, 61, 72))
	draw_line(Vector2(x + 8, y - 25), Vector2(x + w_len - 10, y - 25), Color8(240, 255, 255) if clean else Color8(221, 220, 205), 1)

func draw_pallet_station(x: float, input_station: bool, state: Dictionary, w: Dictionary) -> void:
	draw_round_rect(Rect2(x - 16, 516, 171, 7), Color8(164, 136, 96), 2)
	draw_rect(Rect2(x - 10, 524, 22, 7), Color8(101, 89, 66))
	draw_rect(Rect2(x + 110, 524, 22, 7), Color8(101, 89, 66))

	var output_id = Constants.WASH.outputs.get(w.product, "")
	var count = FoundryEngine.available(state, w.product) if input_station else state.goods.get(output_id, 0)
	for i in range(mini(3, int(count))):
		draw_pipe_tube(Vector2(x + float(i) * 4.0, 511.0 - float(i) * 15.0), not input_station, w, state)

	var label = ("NEOČISTENÉ" if input_station else "OPRACOVANÉ") + " · " + str(count) + " ks"
	draw_canvas_text(label, Vector2(x + 64, 542), Color8(200, 215, 213), 11, HORIZONTAL_ALIGNMENT_CENTER, true)

func draw_foreman_patrol(state: Dictionary) -> void:
	var master = FoundryEngine.profile(FoundryEngine.duty(state, "foreman"))
	if master == null or master.is_empty():
		return
	var phase = fmod(time, 24.0)
	var walking = (phase < 10.0 or (phase >= 12.0 and phase < 22.0))
	var progress = (phase / 10.0) if phase < 10.0 else (1.0 if phase < 12.0 else ((1.0 - (phase - 12.0) / 10.0) if phase < 22.0 else 0.0))
	var x = 270.0 + progress * 750.0
	var y = 641.0
	var facing = 1.0 if phase < 12.0 else -1.0
	var step = sin(time * 13.0) * 5.0 if walking else 0.0
	draw_foreman(Vector2(x, y), master, time, facing, step, walking)
