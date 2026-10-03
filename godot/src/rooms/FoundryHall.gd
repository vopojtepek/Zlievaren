class_name FoundryHall
extends "res://src/rooms/RoomRenderer.gd"

const POSITIONS = [
	Vector2(365, 330), Vector2(620, 330), Vector2(875, 330),
	Vector2(365, 555), Vector2(620, 555), Vector2(875, 555)
]
const HOME = Vector2(162, 268)
const ROMAN = ["I", "II", "III"]

var time: float = 0.0
var hover_slot: int = -1

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
	if event is InputEventMouseMotion:
		var mouse_pos = get_local_mouse_position()
		var found = -1
		for i in range(POSITIONS.size()):
			var p = POSITIONS[i]
			var rect = Rect2(p.x - 90, p.y - 130, 180, 160)
			if rect.has_point(mouse_pos):
				found = i
				break
		if found != hover_slot:
			hover_slot = found
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hover_slot >= 0:
			var gm = get_node_or_null("/root/GameManager")
			if gm != null:
				gm.select_machine(hover_slot)

func _draw() -> void:
	var state = get_room_state()
	if state == null or state.is_empty():
		return
	draw_foundry_bg(state)
	draw_furnace(state)
	draw_furnace_worker(state)
	for i in range(POSITIONS.size()):
		draw_slot(state, POSITIONS[i], i)
		draw_operator(state, POSITIONS[i], i)
	draw_transport(state)
	draw_foreman_patrol(state)
	draw_ambient(state)

func draw_foundry_bg(state: Dictionary) -> void:
	# Main wall and floor background
	draw_rect(Rect2(0, 0, 1100, 690), Color8(41, 61, 62))
	var light_level: float = FoundryEngine.daylight(state)
	var night: float = 1.0 - light_level

	# Windows at the top
	draw_rect(Rect2(0, 45, 1100, 105), Color8(50, 71, 69))
	for x in range(25, 1100, 240):
		draw_round_rect(Rect2(x, 49, 170, 74), Color8(28, 46, 48), 2)
		draw_round_rect(Rect2(x + 4, 53, 162, 65), Color8(78, 105, 103), 1)
		var sky_color = Color8(98, 142, 170).lerp(Color8(23, 35, 57), night)
		draw_rect(Rect2(x + 5, 54, 160, 64), sky_color)
		if night > 0.65:
			draw_circle(Vector2(x + 119, 68), 6, Color8(224, 223, 191))
		else:
			var sun_y = 65.0 + abs(FoundryEngine.hour(state) - 12.0) * 3.0
			draw_circle(Vector2(x + 119, sun_y), 9, Color8(255, 241, 186))
		for j in range(1, 4):
			draw_round_rect(Rect2(x + j * 42, 51, 4, 72), Color8(41, 66, 65), 1)
		draw_rect(Rect2(x, 84, 170, 4), Color8(41, 66, 65))

	# Wall perspective grid lines
	for x in range(0, 1200, 120):
		draw_line(Vector2(x, 153), Vector2(x + 180, 690), Color(0.44, 0.51, 0.48, 0.07), 1)
		draw_line(Vector2(0, 190 + x * 0.44), Vector2(1100, 190 + x * 0.44), Color(0.54, 0.58, 0.55, 0.07), 1)
	for x in range(0, 1100, 225):
		draw_rect(Rect2(x + 2, 0, 17, 180), Color8(28, 48, 50))
		draw_rect(Rect2(x + 5, 0, 4, 178), Color8(73, 97, 96))

	# Pipes and rails
	draw_pipe(0, 135, 1100, 10)
	draw_pipe(15, 165, 1090, 8)
	draw_rect(Rect2(0, 184, 1100, 8), Color8(23, 45, 48))
	draw_rect(Rect2(0, 192, 1100, 3), Color8(105, 117, 104))

	# Overhead casting rail
	draw_rect(Rect2(0, 19, 1100, 13), Color8(167, 135, 75))
	draw_rect(Rect2(0, 22, 1100, 3), Color8(212, 179, 101))
	draw_rect(Rect2(0, 33, 1100, 5), Color8(20, 41, 43))
	for i in range(15):
		draw_line(Vector2(i * 78 + 13, 20), Vector2(i * 78 + 26, 30), Color8(86, 76, 52), 3)

	# Safe walking lane dashed lines
	for y in [370.0, 601.0]:
		draw_dash_line(Vector2(230, y), Vector2(1035, y), Color(0.75, 0.63, 0.39, 0.33), 2.0, 17.0, 10.0)
	draw_line(Vector2(215, 202), Vector2(215, 645), Color(0.75, 0.63, 0.39, 0.31), 2.0)
	draw_canvas_text("ODLIEVACIA HALA", Vector2(641, 656), Color8(120, 148, 145), 12, HORIZONTAL_ALIGNMENT_CENTER, true)

	draw_stock(state)

	# Floor drain
	draw_round_rect(Rect2(50, 566, 120, 18), Color8(25, 47, 49), 3)
	for i in range(13):
		draw_line(Vector2(56 + i * 8, 568), Vector2(52 + i * 8, 581), Color8(66, 97, 93), 2)

func draw_stock(state: Dictionary) -> void:
	draw_canvas_text("VSÁDZKA · " + str(FoundryEngine.used(state, "raw")) + " / " + str(FoundryEngine.capacity(state, "raw")) + " kg", Vector2(101, 393), Color8(200, 212, 198), 10)
	var mat_keys = Constants.MATERIALS.keys()
	for i in range(mat_keys.size()):
		var id = mat_keys[i]
		var mat = Constants.MATERIALS[id]
		var x = 27 + i * 31
		var n = state.raw.get(id, 0)
		draw_round_rect(Rect2(x, 409, 27, 27), Color8(35, 58, 62), 2)
		draw_round_rect(Rect2(x + 2, 412, 23, 21), Color8(20, 43, 48), 1)
		if n > 0:
			var mat_col = Color.html(mat.color)
			for k in range(mini(8, int(ceil(float(n) / 4.0)))):
				var pts = PackedVector2Array([
					Vector2(x + 3 + (k % 3) * 7, 430 - int(k / 3) * 6),
					Vector2(x + 8 + (k % 3) * 7, 422 - int(k / 3) * 6),
					Vector2(x + 12 + (k % 3) * 7, 430 - int(k / 3) * 6)
				])
				draw_colored_polygon(pts, mat_col)
		draw_rect(Rect2(x, 432, 27, 4), Color8(113, 131, 122))
		draw_canvas_text(mat.short.to_upper(), Vector2(x + 13, 444), Color.html(mat.color), 8)
		draw_canvas_text(str(n), Vector2(x + 13, 457), Color8(209, 221, 214), 10)

	# Product stock rack on wall
	draw_rect(Rect2(29, 498, 145, 5), Color8(123, 135, 114))
	draw_rect(Rect2(29, 526, 145, 5), Color8(123, 135, 114))
	draw_rect(Rect2(29, 478, 5, 57), Color8(78, 106, 103))
	draw_rect(Rect2(169, 478, 5, 57), Color8(78, 106, 103))

	var prod_keys = Constants.PRODUCTS.keys()
	var j = 0
	for p_id in prod_keys:
		var p = Constants.PRODUCTS[p_id]
		if p.finished:
			continue
		var px = 48 + j * 36
		var count = state.goods.get(p_id, 0)
		var r = 11.0 if p_id == "ring" else (8.0 if p_id == "bronze_bushing" else 9.0)
		var col = Color.html(p.color)
		if count == 0:
			col.a = 0.2
		draw_round_rect(Rect2(px - r, 483, r * 2, 13), col, 2)
		draw_circ(Vector2(px, 491), r, col)
		draw_circ(Vector2(px, 491), 3.0 if p_id == "bronze_bushing" else 6.0, Color8(20, 45, 52))
		draw_canvas_text(p.code + " " + str(count), Vector2(px, 516), col, 9)
		j += 1

	draw_canvas_text("VÝROBKY · " + str(FoundryEngine.used(state, "goods")) + " / " + str(FoundryEngine.capacity(state, "goods")) + " ks", Vector2(102, 548), Color8(180, 199, 189), 10)

func furnace_tilt(state: Dictionary) -> float:
	var d = state.delivery
	if d == null or d.slot < 0 or d.slot >= state.machines.size():
		return 0.0
	var m = state.machines[d.slot]
	if m == null or d.returnElapsed != null or FoundryEngine.stage(m) != "loading":
		return 0.0
	var p = clampf((float(m.elapsed) - Constants.FLOW.spinup) / (Constants.FLOW.loadEnd - Constants.FLOW.spinup), 0.0, 1.0)
	return 0.52 * sin(p * PI)

func draw_furnace(state: Dictionary) -> void:
	var pouring: bool = false
	for m in state.machines:
		if m != null and FoundryEngine.stage(m) == "pouring":
			pouring = true
			break
	var pulse = 1.0 + sin(time * 2.2) * 0.07
	draw_glow(Vector2(105, 242), 94, Color8(255, 147, 47), pulse * (0.16 if pouring else 0.33))

	# Squat cube furnace with 3D bevels
	var fx = 98.0
	var fy = 320.0
	draw_oval(Vector2(fx + 10, fy + 10), 64, 18, Color(0.06, 0.16, 0.17, 0.4))
	draw_round_rect(Rect2(fx - 42, fy - 76, 84, 76), Color8(116, 123, 104), 3)
	draw_poly(PackedVector2Array([Vector2(fx + 42, fy - 76), Vector2(fx + 62, fy - 94), Vector2(fx + 62, fy - 18), Vector2(fx + 42, fy)]), Color8(64, 87, 85), Color8(25, 54, 56))
	draw_poly(PackedVector2Array([Vector2(fx - 42, fy - 76), Vector2(fx - 22, fy - 94), Vector2(fx + 62, fy - 94), Vector2(fx + 42, fy - 76)]), Color8(164, 161, 138), Color8(82, 107, 97))
	draw_line(Vector2(fx - 41, fy - 74), Vector2(fx + 39, fy - 74), Color8(208, 195, 154), 2)
	draw_round_rect(Rect2(fx - 37, fy - 68, 74, 55), Color8(98, 110, 94), 2)

	for row in range(3):
		draw_line(Vector2(fx - 36, fy - 52 + row * 16), Vector2(fx + 35, fy - 52 + row * 16), Color8(136, 144, 122), 1)
		for col in range(3):
			var lx = fx - 27 + col * 29 + (row % 2) * 12
			draw_line(Vector2(lx, fy - 66 + row * 16), Vector2(lx, fy - 54 + row * 16), Color8(75, 98, 86), 1)

	draw_round_rect(Rect2(fx - 30, fy - 12, 60, 10), Color8(43, 72, 66), 2)
	draw_canvas_text("PEC 01", Vector2(fx, fy - 7), Color8(203, 211, 181), 9, HORIZONTAL_ALIGNMENT_CENTER, true)
	draw_rect(Rect2(fx - 35, fy, 11, 7), Color8(28, 53, 54))
	draw_rect(Rect2(fx + 29, fy, 11, 7), Color8(28, 53, 54))

	# Crucible top and tilting spout
	var tilt = furnace_tilt(state)
	draw_oval(Vector2(fx + 9, fy - 83), 35, 13, Color(1.0, 0.73, 0.4, 0.33))
	draw_circ(Vector2(fx - 25, fy - 86), 5, Color8(199, 199, 167))

	# Tilting lid
	var lid_center = Vector2(fx - 25, fy - 86)
	var lid_rot_pts = PackedVector2Array()
	for k in range(24):
		var a = float(k) * TAU / 24.0
		var p = Vector2(fx + 9 + cos(a) * 35.0, fy - 83 + sin(a) * 13.0)
		var rel = (p - lid_center).rotated(tilt)
		lid_rot_pts.append(lid_center + rel)
	draw_colored_polygon(lid_rot_pts, Color8(109, 113, 96))

	# Status text
	draw_canvas_text("TAVENINA", Vector2(112, 344), Color8(187, 202, 184), 11)
	draw_canvas_text("1 700 °C", Vector2(112, 364), Color8(255, 189, 120), 18, HORIZONTAL_ALIGNMENT_CENTER, true)

func draw_furnace_worker(state: Dictionary) -> void:
	var d = state.delivery
	var loading: bool = (d != null and d.returnElapsed == null and d.slot >= 0 and d.slot < state.machines.size() and state.machines[d.slot] != null and FoundryEngine.stage(state.machines[d.slot]) == "loading")
	var crew = FoundryEngine.profile(FoundryEngine.employee(state, d.furnaceId)) if loading else FoundryEngine.profile(FoundryEngine.duty(state, "furnace"))
	if crew == null or crew.is_empty():
		return
	var tilt = furnace_tilt(state)
	draw_worker(Vector2(34, 328), false, 0.0, false, 1.0, crew, time)
	draw_round_rect(Rect2(49, 296, 12, 14), Color8(37, 73, 82), 2)
	draw_line(Vector2(54, 299), Vector2(60 + tilt * 12, 283 + tilt * 14), Color8(186, 196, 175), 3)
	draw_circle(Vector2(60 + tilt * 12, 283 + tilt * 14), 4, Color8(226, 183, 102))

	var crew_color = Color.html(crew.get("color", "#385f57"))
	draw_line(Vector2(45, 294), Vector2(60 + tilt * 12, 283 + tilt * 14), crew_color, 6)
	draw_circle(Vector2(60 + tilt * 12, 283 + tilt * 14), 3, Color8(216, 191, 152))

	draw_round_rect(Rect2(10, 337, 48, 16), Color8(22, 44, 51, 217), 3)
	draw_canvas_text(crew.get("name", "Tavič"), Vector2(34, 345), Color8(212, 223, 212), 10)
	if loading:
		draw_glow(Vector2(47, 286), 23, Color8(255, 198, 126), 0.1)

func draw_slot(state: Dictionary, p: Vector2, index: int) -> void:
	var selected = (state.selected == index)
	var over = (hover_slot == index)
	var m = state.machines[index]

	# Floor polygon footprint
	var floor_pts = PackedVector2Array([
		p + Vector2(-91, 22), p + Vector2(69, 22), p + Vector2(110, -8), p + Vector2(-51, -8)
	])
	var floor_col = Color(0.51, 0.60, 0.50, 0.14) if selected else Color(0.69, 0.73, 0.60, 0.03)
	var stroke_col = Color(0.74, 0.84, 0.65, 0.54) if selected else Color(0.56, 0.67, 0.63, 0.29)
	draw_poly(floor_pts, floor_col, stroke_col, 1.0)

	if m == null:
		# Empty slot with dashed boundary and price
		var dash_col = Color8(185, 213, 176) if selected else (Color8(208, 216, 193) if over else Color8(122, 154, 145, 107))
		draw_dash_line(p + Vector2(-64, 4), p + Vector2(63, 4), dash_col, 2.0, 7.0, 6.0)
		draw_dash_line(p + Vector2(63, 4), p + Vector2(89, -17), dash_col, 2.0, 7.0, 6.0)
		draw_dash_line(p + Vector2(89, -17), p + Vector2(-36, -17), dash_col, 2.0, 7.0, 6.0)
		draw_dash_line(p + Vector2(-36, -17), p + Vector2(-64, 4), dash_col, 2.0, 7.0, 6.0)

		var buy_fill = Color(0.67, 0.78, 0.68, 0.1) if selected else Color(0.26, 0.36, 0.33, 0.17)
		var buy_stroke = Color(0.70, 0.81, 0.69, 0.54) if selected else Color(0.50, 0.62, 0.55, 0.33)
		draw_circ(p + Vector2(10, -64), 25, buy_fill, buy_stroke, 1.0)
		draw_line(p + Vector2(-1, -64), p + Vector2(21, -64), Color8(193, 217, 185) if selected else Color8(130, 158, 145), 2.0)
		draw_line(p + Vector2(10, -75), p + Vector2(10, -53), Color8(193, 217, 185) if selected else Color8(130, 158, 145), 2.0)
		draw_canvas_text("MIESTO " + str(index + 1).pad_zeros(2), p + Vector2(10, -22), Color8(163, 185, 169), 11)
		draw_canvas_text(str(FoundryEngine.price(state)) + " ₵", p + Vector2(10, 49), Color8(193, 217, 180) if selected else Color8(134, 165, 149), 13)
	else:
		draw_machine(p, m, index, selected or over, state)

func draw_machine(p: Vector2, m: Dictionary, index: int, selected: bool, state: Dictionary) -> void:
	var stage = FoundryEngine.stage(m)
	var failed = (m.state == "failed")
	var working = (m.state == "working" or failed)
	var ready = (m.state == "ready" or m.state == "unloading")
	var temp = FoundryEngine.temperature(m)
	var has_metal = (ready and not (m.state == "unloading" and float(m.unloadElapsed) > 0.7)) or (working and float(m.elapsed) > Constants.FLOW.carryEnd)
	var hot = maxf(0.0, (temp - 430.0) / 1020.0) if working else 0.0

	var body_col = Color8(100, 126, 120) if m.level == 1 else (Color8(100, 133, 138) if m.level == 2 else Color8(135, 145, 129))
	var side_col = Color8(60, 89, 87) if m.level == 1 else (Color8(56, 93, 100) if m.level == 2 else Color8(83, 105, 97))
	var top_col = Color8(140, 161, 149) if m.level == 1 else (Color8(142, 174, 176) if m.level == 2 else Color8(180, 189, 162))

	# Machine shadow
	draw_oval(p + Vector2(16, 14), 80, 20, Color(0.04, 0.15, 0.16, 0.32))
	if hot > 0.0:
		draw_glow(p + Vector2(0, -37), 107, Color8(255, 152, 63), hot * 0.15)
	if ready:
		draw_glow(p + Vector2(0, -43), 91, Color8(187, 229, 143), 0.07)

	# Mounting feet
	draw_round_rect(Rect2(p.x - 51, p.y - 7, 15, 22), Color8(37, 61, 60), 3)
	draw_round_rect(Rect2(p.x + 37, p.y - 7, 15, 22), Color8(37, 61, 60), 3)
	draw_round_rect(Rect2(p.x - 50, p.y - 5, 13, 4), Color8(161, 171, 140))
	draw_round_rect(Rect2(p.x + 38, p.y - 5, 13, 4), Color8(161, 171, 140))

	# 3D Perspective Body
	var side_pts = PackedVector2Array([
		p + Vector2(55, -151), p + Vector2(80, -169), p + Vector2(80, -13), p + Vector2(55, 5)
	])
	draw_poly(side_pts, side_col, Color8(23, 46, 49), 1.0)

	var top_pts = PackedVector2Array([
		p + Vector2(-55, -151), p + Vector2(-30, -169), p + Vector2(80, -169), p + Vector2(55, -151)
	])
	draw_poly(top_pts, top_col, Color8(72, 96, 90), 1.0)

	draw_round_rect(Rect2(p.x - 55, p.y - 151, 110, 156), body_col, 4)
	draw_line(p + Vector2(-53, -148), p + Vector2(51, -148), Color(0.77, 0.81, 0.67, 0.47), 2)

	# Inner chamber
	draw_round_rect(Rect2(p.x - 43, p.y - 133, 73, 105), Color8(52, 75, 73), 4)
	draw_round_rect(Rect2(p.x - 39, p.y - 129, 65, 98), Color8(18, 41, 45), 3)
	draw_round_rect(Rect2(p.x - 35, p.y - 124, 57, 87), Color8(27, 52, 55), 4)

	# Rotating tube & mould bore
	var p_id = m.get("product", "iron_pipe")
	var product = Constants.PRODUCTS.get(p_id, Constants.PRODUCTS["iron_pipe"])
	var bore = 10.0 if p_id == "bronze_bushing" else (19.0 if p_id == "ring" else 15.0)
	var cx = p.x - 7.0
	var cy = p.y - 82.0

	var angle = 0.4
	if working:
		if stage == "spinup":
			angle = float(m.elapsed) * float(m.elapsed) * 2.2
		else:
			angle = time * (2.0 if stage == "cooling" else 7.0)

	if hot > 0.0:
		draw_glow(Vector2(cx, cy), 52, heat_color(temp), hot * 0.36)

	draw_circ(Vector2(cx, cy), 30, Color8(20, 40, 44), Color8(121, 147, 135))
	draw_circ(Vector2(cx, cy), 27, Color8(89, 112, 107))

	# Metal ring color
	var metal_col = Color.html(product.color) if (ready or temp < 400.0) else heat_color(temp)
	var drum_ring_col = metal_col if has_metal else Color8(179, 194, 176)
	draw_circ(Vector2(cx, cy), 25, drum_ring_col)

	# Inner bore depth
	draw_circ(Vector2(cx, cy), bore, Color8(80, 46, 36) if (has_metal and temp > 400.0) else Color8(18, 45, 50))
	draw_circ(Vector2(cx + 1, cy + 2), maxf(1.0, bore - 4.0), Color8(17, 43, 48))

	# Spinning spoke marks
	for k in range(6):
		var sp_angle = angle + float(k) * TAU / 6.0
		var r1 = Vector2(cx + cos(sp_angle) * 18.0, cy + sin(sp_angle) * 18.0)
		var r2 = Vector2(cx + cos(sp_angle) * 24.0, cy + sin(sp_angle) * 24.0)
		draw_line(r1, r2, Color(1.0, 0.91, 0.69, 0.6) if has_metal else Color(0.82, 0.86, 0.77, 0.53), 2.0)
	var marker_pos = Vector2(cx + cos(angle) * 21.0, cy + sin(angle) * 21.0)
	draw_circle(marker_pos, 2.4, Color8(255, 239, 187) if has_metal else Color8(227, 229, 206))

	draw_round_rect(Rect2(p.x - 32, p.y - 46, 51, 5), Color8(83, 105, 92), 2)
	draw_rect(Rect2(p.x - 25, p.y - 43, 8, 8), Color8(21, 46, 49))
	draw_rect(Rect2(p.x + 4, p.y - 43, 8, 8), Color8(21, 46, 49))

	draw_cooling(p, m, index)

	# Hinged Door: Open vs Closed
	if m.state == "idle" or ready:
		# Door open to the left
		var door_outer = PackedVector2Array([
			p + Vector2(-43, -134), p + Vector2(-78, -144), p + Vector2(-78, -40), p + Vector2(-43, -29)
		])
		draw_poly(door_outer, Color8(113, 137, 128), Color(0.76, 0.80, 0.64, 0.4), 1.0)

		var door_inner = PackedVector2Array([
			p + Vector2(-48, -124), p + Vector2(-72, -131), p + Vector2(-72, -53), p + Vector2(-48, -44)
		])
		draw_poly(door_inner, Color8(38, 62, 63), Color(0.64, 0.73, 0.60, 0.27), 1.0)
		draw_line(p + Vector2(-69, -91), p + Vector2(-69, -78), Color8(184, 201, 172), 3)
		draw_round_rect(Rect2(p.x - 47, p.y - 117, 6, 13), Color8(168, 181, 153), 2)
		draw_round_rect(Rect2(p.x - 47, p.y - 51, 6, 13), Color8(168, 181, 153), 2)
	else:
		# Door closed with inspection window
		draw_round_rect(Rect2(p.x - 45, p.y - 135, 78, 8), Color8(138, 160, 143), 2)
		draw_round_rect(Rect2(p.x - 45, p.y - 35, 78, 8), Color8(80, 111, 103), 2)
		draw_round_rect(Rect2(p.x - 45, p.y - 133, 8, 104), Color8(138, 160, 143), 2)
		draw_round_rect(Rect2(p.x + 25, p.y - 131, 8, 100), Color8(72, 105, 97), 2)
		draw_round_rect(Rect2(p.x + 28, p.y - 87, 4, 24), Color8(194, 204, 172), 2)
		draw_line(p + Vector2(-30, -117), p + Vector2(19, -52), Color(0.75, 0.87, 0.78, 0.05), 5)
		draw_line(p + Vector2(-21, -120), p + Vector2(22, -61), Color(0.82, 0.96, 0.85, 0.04), 9)

	# Machine Level Plate & Indicators
	draw_round_rect(Rect2(p.x + 36, p.y - 133, 13, 45), Color8(44, 72, 73), 2)
	draw_round_rect(Rect2(p.x + 38, p.y - 128, 9, 15), Color8(16, 46, 50), 2)
	draw_canvas_text(str(m.level), Vector2(p.x + 42.5, p.y - 120), Color8(186, 228, 178), 9)

	var st_light_col = Color8(140, 227, 255) if stage == "cooling" else (Color8(255, 183, 102) if working else (Color8(199, 232, 160) if ready else Color8(148, 180, 149)))
	draw_circle(p + Vector2(42, -101), 4, st_light_col)
	draw_circ(p + Vector2(42, -77), 6, Color8(43, 68, 68), Color8(165, 182, 156))
	draw_circle(p + Vector2(42, -77), 3, Color8(196, 129, 86))

	draw_round_rect(Rect2(p.x - 44, p.y - 20, 64, 10), Color8(37, 68, 67), 2)
	draw_canvas_text("CENTRA · " + ROMAN[m.level - 1], Vector2(p.x - 12, p.y - 15), Color8(181, 198, 175), 8, HORIZONTAL_ALIGNMENT_CENTER, true)
	draw_round_rect(Rect2(p.x + 27, p.y - 20, 21, 10), Color8(189, 173, 107), 1)
	draw_canvas_text("⚡", Vector2(p.x + 37, p.y - 15), Color8(57, 62, 42), 9)

	for j in range(5):
		draw_line(p + Vector2(62, -115 + j * 6), p + Vector2(73, -123 + j * 6), Color8(25, 47, 52), 2)
	for rivet in [Vector2(-49, -143), Vector2(48, -143), Vector2(-49, -3), Vector2(48, -3)]:
		draw_circle(p + rivet, 2, Color8(192, 199, 170))

	# Status Tag Above Machine
	var tag_y = -195.0
	draw_round_rect(Rect2(p.x - 66, p.y + tag_y - 11, 140, 23), Color8(120, 53, 35, 245) if failed else Color8(23, 45, 49, 237), 4)
	draw_circle(p + Vector2(-54, tag_y), 3.5, Color8(255, 171, 99) if working else (Color8(190, 226, 145) if ready else Color8(143, 174, 158)))

	var tag_text = "NEPODARENÁ RÚRA" if failed else (str(int(temp)) + " °C" if (working and has_metal) else (Constants.STAGES.get(stage, stage).to_upper() if working else ("NA PALETU" if m.state == "unloading" else ("ČAKÁ NA OBSLUHU" if ready else ("PRIPRAVENÁ" if FoundryEngine.operator(state, index) != null else "CHÝBA OBSLUHA")))))
	draw_canvas_text(tag_text, Vector2(p.x + 8, p.y + tag_y), Color8(255, 197, 132) if working else (Color8(205, 230, 173) if ready else Color8(185, 202, 188)), 10)

	if working:
		var dur = FoundryEngine.duration(m.level, p_id)
		var pr = clampf(float(m.elapsed) / maxf(1.0, float(dur)), 0.0, 1.0)
		draw_round_rect(Rect2(p.x - 53, p.y - 174, 120, 3), Color8(24, 47, 50), 2)
		draw_round_rect(Rect2(p.x - 53, p.y - 174, 120.0 * pr, 3), Color8(229, 173, 105), 2)

	draw_canvas_text(str(index + 1).pad_zeros(2) + " / " + product.code + " / MK " + ROMAN[m.level - 1] + (" · SÉRIA" if m.auto else ""), Vector2(p.x + 6, p.y + 44), Color8(215, 227, 194) if selected else Color8(166, 188, 169), 11, HORIZONTAL_ALIGNMENT_CENTER, true)

	draw_external_steam(p, m, index, state)
	draw_reject_sparks(p, m, index)

func draw_cooling(p: Vector2, m: Dictionary, index: int) -> void:
	if FoundryEngine.stage(m) != "cooling":
		return
	var clock = time + float(index) * 0.29
	# Nozzles spray inside the chamber
	for j in range(2):
		var nx = p.x + (-30.0 if j == 0 else 18.0)
		var ny = p.y - 110.0
		var side = -1.0 if j == 0 else 1.0
		var hit_x = p.x + (-25.0 if j == 0 else 11.0)
		var hit_y = p.y - 97.0

		draw_line(Vector2(nx, p.y - 120), Vector2(nx, p.y - 114), Color8(112, 148, 159), 3)
		draw_oval(Vector2(nx, ny), 2.5, 1.2, Color8(202, 247, 255))

		for jet in range(3):
			var end_x = hit_x + float(jet - 1) * 3.3
			var end_y = hit_y + float(jet - 1) * 1.6
			draw_line(Vector2(nx, ny), Vector2(end_x, end_y), Color(0.50, 0.87, 0.97, 0.53), 1.25)
			for drop in range(3):
				var pr = fmod(clock * 2.9 + float(drop) / 3.0 + float(jet) * 0.17 + float(j) * 0.31, 1.0)
				var q = maxf(0.0, pr - 0.18)
				var d1 = Vector2(nx + (end_x - nx) * q, ny + (end_y - ny) * q)
				var d2 = Vector2(nx + (end_x - nx) * pr, ny + (end_y - ny) * pr)
				draw_line(d1, d2, Color8(215, 250, 255), 1.3)

	# Runoff in drip tray
	draw_oval(p + Vector2(-7, -39), 26, 2.5, Color(0.46, 0.79, 0.90, 0.36))

func draw_external_steam(p: Vector2, m: Dictionary, index: int, state: Dictionary) -> void:
	var cooling = (FoundryEngine.stage(m) == "cooling")
	var tail = 0.0
	if m.state == "ready" and m.finishedAt != null and is_finite(float(m.finishedAt)):
		tail = clampf(1.0 - (state.clock - float(m.finishedAt)) / 3.0, 0.0, 1.0)
	if not cooling and tail <= 0.0:
		return

	var heat = clampf((FoundryEngine.temperature(m) - 180.0) / 1200.0, 0.0, 1.0)
	var strength = (0.45 + 0.55 * heat) if cooling else (tail * 0.42)
	for i in range(16):
		var age = fmod(time * 0.23 + float(i) / 16.0 + float(index) * 0.17, 1.0)
		var spread = 35.0 + age * 95.0 + heat * 20.0
		var px = p.x + 8.0 + sin(float(i) * 1.8 + time * 0.38) * age * 60.0 + age * 28.0
		var py = p.y - 148.0 - age * (180.0 + heat * 75.0)
		var alpha = sin(age * PI) * (0.27 + 0.11 * heat) * strength
		draw_circle(Vector2(px, py), spread * 0.4, Color(0.90, 0.96, 0.96, alpha * 0.6))

func draw_reject_sparks(p: Vector2, m: Dictionary, index: int) -> void:
	if m.state != "failed":
		return
	var age = float(m.failedElapsed)
	var fade = clampf((Constants.FAILURE_SECONDS - age) / 0.85, 0.0, 1.0)
	var center = p + Vector2(-7, -82)
	draw_glow(center, 105, Color8(255, 123, 36), 0.34 * fade)
	draw_glow(center, 38, Color8(255, 210, 123), 0.5 * fade)

	# 128 optimized ballistic sparks
	for k in range(128):
		var birth = float(k) / 45.0
		var life = 1.1 + fmod(float(k) * 0.19, 0.55)
		var t = age - birth
		if t < 0.0 or t > life:
			continue
		var a = float(k) * 0.31 + birth * 8.0
		var speed = 105.0 + fmod(float(k) * 17.0, 170.0)
		var vx = cos(a) * speed
		var vy = sin(a) * speed * 0.76 - 28.0
		var sx = cos(a) * 19.0
		var sy = sin(a) * 19.0
		var px = sx + vx * t
		var py = sy + vy * t + 94.0 * t * t
		var q = t / life
		var alpha = minf(1.0, t * 35.0) * (1.0 - q * 0.7) * fade
		var spark_col = Color8(255, 245, 201, int(alpha * 255)) if q < 0.22 else (Color8(255, 194, 102, int(alpha * 255)) if q < 0.58 else Color8(255, 107, 46, int(alpha * 255)))
		draw_circle(center + Vector2(px, py), 1.5, spark_col)

func draw_operator(state: Dictionary, p: Vector2, i: int) -> void:
	var m = state.machines[i]
	if m == null:
		return
	# Pallet with stacked products on the right of the machine
	var pallet_counts = state.pallets[i]
	var count = 0
	for c in pallet_counts.values():
		count += int(c)
	var x = p.x + 112.0
	var y = p.y + 18.0

	draw_oval(Vector2(x, y + 8), 34, 11, Color(0.06, 0.14, 0.16, 0.53))
	draw_poly(PackedVector2Array([Vector2(x - 27, y - 8), Vector2(x + 20, y - 17), Vector2(x + 34, y - 4), Vector2(x - 13, y + 6)]), Color8(119, 140, 141), Color8(192, 202, 204))
	draw_poly(PackedVector2Array([Vector2(x - 27, y - 8), Vector2(x - 13, y + 6), Vector2(x - 13, y + 13), Vector2(x - 27, y - 1)]), Color8(54, 78, 84))
	draw_poly(PackedVector2Array([Vector2(x - 13, y + 6), Vector2(x + 34, y - 4), Vector2(x + 34, y + 3), Vector2(x - 13, y + 13)]), Color8(76, 100, 107))
	for k in range(4):
		draw_line(Vector2(x - 22 + k * 12, y - 9 - k * 2), Vector2(x - 9 + k * 12, y + 4 - k * 2), Color8(50, 73, 78), 3)

	var ids = []
	for p_id in pallet_counts.keys():
		if pallet_counts[p_id] > 0:
			ids.append(p_id)
	for k in range(mini(3, count)):
		var id = ids[k % ids.size()]
		var yy = y - 12 - k * 8
		var p_col = Color.html(Constants.PRODUCTS[id].color)
		draw_round_rect(Rect2(x - 22, yy - 7, 39, 9), p_col, 3)
		draw_oval(Vector2(x - 21, yy - 2), 5, 6, Color8(194, 208, 204))
		draw_oval(Vector2(x - 21, yy - 2), 2.7, 3.7, Color8(28, 51, 59))
		draw_line(Vector2(x - 16, yy - 6), Vector2(x + 14, yy - 6), Color8(212, 223, 223), 1)

	draw_canvas_text(str(count) + " ks", Vector2(x + 5, y + 24), Color8(199, 212, 205), 10)

	var unloading = (m.state == "unloading")
	var crew = FoundryEngine.profile(FoundryEngine.employee(state, m.unloadEmployeeId)) if unloading else FoundryEngine.operator(state, i)
	var has_crew = (crew != null and not crew.is_empty())
	var crew_name = crew.get("name", "BEZ OBSLUHY") if has_crew else "BEZ OBSLUHY"
	draw_canvas_text(crew_name, Vector2(p.x - 2, p.y + 61), Color8(187, 215, 208) if has_crew else Color8(236, 169, 144), 10)
	if not has_crew:
		return

	var t = minf(1.0, float(m.unloadElapsed) / Constants.UNLOAD_SECONDS) if unloading else 0.0
	var travel = sin(minf(1.0, t * 1.25) * PI * 0.5) if unloading else 0.0
	var wx = p.x + 57.0 + travel * 40.0
	var wy = p.y + 18.0
	draw_worker(Vector2(wx, wy), true, 1.0 if unloading else 0.0, false, 1.0 if unloading else -1.0, crew, time)

	if unloading:
		var lift = minf(1.0, t * 5.0)
		var py = wy - 20.0 - lift * 5.0
		var prod_color = Color.html(Constants.PRODUCTS[m.product].color)
		draw_round_rect(Rect2(wx - 22, py, 43, 11), prod_color, 3)
		draw_line(Vector2(wx - 20, py + 2), Vector2(wx + 18, py + 2), Color8(222, 228, 223), 2)
		draw_oval(Vector2(wx - 22, py + 5), 5, 7, Color8(184, 201, 202))
		draw_oval(Vector2(wx - 22, py + 5), 2.6, 4.5, Color8(32, 57, 67))
		draw_line(Vector2(wx - 11, wy - 23), Vector2(wx - 8, py + 10), Color8(219, 192, 154), 4)
		draw_line(Vector2(wx + 10, wy - 23), Vector2(wx + 12, py + 10), Color8(219, 192, 154), 4)

func delivery_route(slot: int) -> Array:
	var p = POSITIONS[slot]
	var target = Vector2(p.x - 65, p.y - 114)
	var aisle = p.y + 58 - 142
	return [HOME, Vector2(226, HOME.y), Vector2(226, aisle), Vector2(target.x, aisle), target]

func point_on_route(points: Array, progress: float) -> Vector2:
	var pr = clampf(progress, 0.0, 1.0)
	var seg_lens = []
	var total_len: float = 0.0
	for i in range(points.size() - 1):
		var d = points[i].distance_to(points[i + 1])
		seg_lens.append(d)
		total_len += d
	var target_d = total_len * pr
	for i in range(seg_lens.size()):
		if target_d <= seg_lens[i]:
			var f = target_d / maxf(1.0, seg_lens[i])
			return points[i].lerp(points[i + 1], f)
		target_d -= seg_lens[i]
	return points[-1]

func draw_transport(state: Dictionary) -> void:
	var d = state.delivery
	var ladle_pos = HOME
	var tilt: float = 0.0
	var fill: float = 0.0
	var pouring: bool = false
	var target_slot: int = 0

	if d != null and d.slot >= 0 and d.slot < POSITIONS.size():
		target_slot = d.slot
		var m = state.machines[d.slot]
		var route = delivery_route(d.slot)
		if d.returnElapsed != null:
			var pr = float(d.returnElapsed) / Constants.FLOW.returnTime
			var rev_route = route.duplicate()
			rev_route.reverse()
			ladle_pos = point_on_route(rev_route, pr)
		elif m != null:
			var el = float(m.elapsed)
			if el < Constants.FLOW.spinup:
				ladle_pos = HOME
			elif el < Constants.FLOW.loadEnd:
				ladle_pos = HOME
				fill = clampf((el - Constants.FLOW.spinup) / (Constants.FLOW.loadEnd - Constants.FLOW.spinup), 0.0, 1.0)
			elif el < Constants.FLOW.carryEnd:
				var pr = (el - Constants.FLOW.loadEnd) / (Constants.FLOW.carryEnd - Constants.FLOW.loadEnd)
				ladle_pos = point_on_route(route, pr)
				fill = 1.0
			elif el < Constants.FLOW.pourEnd:
				ladle_pos = route[-1]
				var pr = (el - Constants.FLOW.carryEnd) / (Constants.FLOW.pourEnd - Constants.FLOW.carryEnd)
				tilt = 0.86 * minf(clampf(pr / 0.18, 0.0, 1.0), clampf((1.0 - pr) / 0.13, 0.0, 1.0))
				fill = 1.0 - clampf((pr - 0.1) / 0.82, 0.0, 1.0)
				pouring = (pr > 0.1 and pr < 0.92)

	# Overhead travelling hoist
	draw_round_rect(Rect2(ladle_pos.x - 22, 28, 44, 15), Color8(165, 139, 81), 3)
	draw_round_rect(Rect2(ladle_pos.x - 17, 31, 34, 4), Color8(211, 177, 107), 2)
	draw_circle(Vector2(ladle_pos.x - 13, 43), 4, Color8(35, 61, 61))
	draw_circle(Vector2(ladle_pos.x + 13, 43), 4, Color8(35, 61, 61))

	# Suspension cables & yoke
	draw_line(Vector2(ladle_pos.x - 3, 43), Vector2(ladle_pos.x - 3, ladle_pos.y - 62), Color8(177, 180, 160), 2)
	draw_line(Vector2(ladle_pos.x + 3, 43), Vector2(ladle_pos.x + 3, ladle_pos.y - 62), Color8(100, 126, 117), 2)
	draw_round_rect(Rect2(ladle_pos.x - 20, ladle_pos.y - 62, 40, 6), Color8(139, 150, 143), 2)
	draw_line(Vector2(ladle_pos.x - 15, ladle_pos.y - 60), Vector2(ladle_pos.x + 15, ladle_pos.y - 60), Color8(195, 204, 196), 1)

	# Ladle pot
	var pot_origin = Vector2(ladle_pos.x, ladle_pos.y)
	draw_round_rect(Rect2(pot_origin.x - 22, pot_origin.y - 15, 44, 38), Color8(130, 144, 135), 6)
	if fill > 0.0:
		draw_circle(pot_origin, 12.0 * fill, Color8(255, 186, 89))
		draw_glow(pot_origin, 35, Color8(255, 150, 50), 0.3 * fill)

	# Molten metal pour stream
	if pouring:
		var target_p = POSITIONS[target_slot]
		draw_stream(pot_origin + Vector2(15, 10), Vector2(target_p.x - 7, target_p.y - 82), 5.0, time)

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

func draw_ambient(state: Dictionary) -> void:
	var night: float = 1.0 - FoundryEngine.daylight(state)
	if night > 0.05:
		draw_rect(Rect2(0, 0, 1100, 690), Color(0.03, 0.07, 0.15, night * 0.36))
		for x in [365.0, 620.0, 875.0]:
			draw_glow(Vector2(x, 55), 53, Color8(255, 207, 138), night * 0.3)
	draw_glow(Vector2(106, 211), 75, Color8(255, 151, 55), 0.14 + night * 0.18)
