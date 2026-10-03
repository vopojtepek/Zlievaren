class_name CncHall
extends "res://src/rooms/RoomRenderer.gd"

const CNC_POSITIONS = [
	Vector2(123, 144), Vector2(366, 144), Vector2(609, 144),
	Vector2(852, 144), Vector2(609, 441), Vector2(852, 441),
	Vector2(72, 408)
]

var time: float = 0.0
var hover_cnc: int = -1

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
		for i in range(CNC_POSITIONS.size()):
			var p = CNC_POSITIONS[i]
			var w = 192.0 * (1.17 if i == 6 else 1.0)
			var h = 130.0 * (1.2 if i == 6 else 1.0)
			var rect = Rect2(p.x, p.y, w, h)
			if rect.has_point(mouse_pos):
				found = i
				break
		if found != hover_cnc:
			hover_cnc = found
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_input(InputEventMouseMotion.new())
		if hover_cnc >= 0:
			var gm = get_node_or_null("/root/GameManager")
			if gm != null:
				var owned = gm.state.cncOwned[hover_cnc]
				if not owned:
					gm.execute({ "type": "cnc", "slot": hover_cnc, "action": "buy" })
				else:
					gm.execute({ "type": "cnc", "slot": hover_cnc, "action": "toggle" })

func _draw() -> void:
	var state = get_room_state()
	if state == null or state.is_empty():
		return

	var daylight = FoundryEngine.daylight(state)
	var night = 1.0 - daylight

	# Background gradient
	draw_gradient_rect(Rect2(0, 0, 1100, 690), PackedColorArray([Color("#3f5452"), Color("#344b4a"), Color("#596961"), Color("#374d49")]), PackedFloat32Array([0, 0.16, 0.161, 1]))

	# Wall columns and high windows
	for x in range(25, 1100, 180):
		draw_rect(Rect2(x, 0, 8, 107), Color8(32, 58, 59))
		var win_col = Color8(136, 163, 158) if daylight > 0.4 else Color8(39, 61, 77)
		draw_round_rect(Rect2(x + 32, 26, 104, 48), win_col, 2)
		draw_line(Vector2(x + 83, 26), Vector2(x + 83, 74), Color8(59, 85, 84), 4)
		draw_line(Vector2(x + 32, 51), Vector2(x + 136, 51), Color8(59, 85, 84), 3)

	draw_rect(Rect2(0, 104, 1100, 7), Color8(29, 55, 54))
	draw_pipe(0, 88, 1100, 5)

	for y in range(145, 690, 57):
		draw_line(Vector2(0, y), Vector2(1100, y), Color(0.72, 0.79, 0.68, 0.08))
	for x in range(0, 1100, 110):
		draw_line(Vector2(x, 111), Vector2(x - 35, 690), Color(0.72, 0.79, 0.68, 0.08))

	# Marked Hall Transport Road around machinery
	var road_pts = PackedVector2Array([
		Vector2(359, 317), Vector2(1100, 317), Vector2(1100, 405), Vector2(553, 405),
		Vector2(553, 617), Vector2(1100, 617), Vector2(1100, 690), Vector2(0, 690),
		Vector2(0, 617), Vector2(359, 617)
	])
	draw_poly(road_pts, Color8(39, 62, 64))
	draw_line(Vector2(365, 315), Vector2(1100, 315), Color8(215, 189, 117), 3)
	draw_line(Vector2(356, 320), Vector2(356, 614), Color8(215, 189, 117), 3)
	draw_line(Vector2(0, 614), Vector2(356, 614), Color8(215, 189, 117), 3)
	draw_line(Vector2(556, 408), Vector2(1100, 408), Color8(215, 189, 117), 3)
	draw_line(Vector2(556, 408), Vector2(556, 614), Color8(215, 189, 117), 3)
	draw_line(Vector2(556, 614), Vector2(1100, 614), Color8(215, 189, 117), 3)
	draw_dash_line(Vector2(457, 360), Vector2(1100, 360), Color(0.68, 0.74, 0.62, 0.31), 2.0, 22.0, 20.0)
	draw_dash_line(Vector2(457, 360), Vector2(457, 652), Color(0.68, 0.74, 0.62, 0.31), 2.0, 22.0, 20.0)
	draw_dash_line(Vector2(0, 652), Vector2(1100, 652), Color(0.68, 0.74, 0.62, 0.31), 2.0, 22.0, 20.0)
	draw_canvas_text("HALOVÁ CESTA", Vector2(767, 670), Color8(143, 164, 156), 10, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Programmer Workstation: Desk, Monitor, Keyboard, Mouse, Wheeled Chair
	draw_workstation()

	# Draw CNC Machines
	for i in range(CNC_POSITIONS.size()):
		draw_cnc_machine(CNC_POSITIONS[i], i, state)

	draw_canvas_text("PÔVODNÁ LINKA / CNC 1–6", Vector2(634, 85), Color8(208, 220, 197), 11, HORIZONTAL_ALIGNMENT_CENTER, true)
	draw_canvas_text("NOVÁ LINKA", Vector2(193, 376), Color8(228, 209, 188), 11, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Night ambient & hall lights
	if night > 0.05:
		draw_rect(Rect2(0, 0, 1100, 690), Color(0.03, 0.07, 0.14, night * 0.21))
		for x in [210.0, 487.0, 767.0, 1010.0]:
			draw_round_rect(Rect2(x - 25, 8, 50, 8), Color8(36, 62, 60), 3)
			draw_round_rect(Rect2(x - 20, 16, 40, 3), Color8(226, 230, 200), 1)
			draw_glow(Vector2(x, 50), 85, Color8(229, 230, 188), 0.08 + night * 0.1)

func draw_workstation() -> void:
	# Floor shadow
	draw_oval(Vector2(66, 370), 57, 14, Color(0.08, 0.18, 0.20, 0.31))
	# Desk legs
	for pt in [Vector2(21, 322), Vector2(69, 327), Vector2(21, 349), Vector2(69, 354)]:
		draw_line(pt, pt + Vector2(0, 24), Color8(164, 175, 170), 3)
		draw_line(pt + Vector2(0, 24), pt + Vector2(5, 24), Color8(82, 105, 102), 2)
	draw_line(Vector2(22, 354), Vector2(68, 359), Color8(98, 124, 118), 2)

	# PC Tower
	draw_round_rect(Rect2(26, 351, 19, 25), Color8(35, 50, 56), 2)
	draw_poly(PackedVector2Array([Vector2(45, 351), Vector2(51, 345), Vector2(51, 370), Vector2(45, 376)]), Color8(22, 42, 48))
	draw_round_rect(Rect2(30, 355, 11, 2), Color8(16, 30, 39), 1)
	draw_circle(Vector2(40, 361), 1.7, Color8(141, 230, 194))

	# Desk top
	draw_poly(PackedVector2Array([Vector2(17, 308), Vector2(68, 316), Vector2(80, 348), Vector2(28, 340)]), Color8(193, 164, 123), Color8(213, 189, 148))
	draw_poly(PackedVector2Array([Vector2(28, 340), Vector2(80, 348), Vector2(80, 355), Vector2(28, 347)]), Color8(140, 114, 85))

	# Monitor
	draw_poly(PackedVector2Array([Vector2(29, 325), Vector2(35, 321), Vector2(46, 329), Vector2(40, 333)]), Color8(53, 71, 74))
	draw_line(Vector2(35, 311), Vector2(35, 326), Color8(59, 77, 80), 4)
	draw_poly(PackedVector2Array([Vector2(17, 282), Vector2(37, 297), Vector2(42, 322), Vector2(22, 307)]), Color8(26, 41, 47), Color8(114, 137, 135))
	draw_poly(PackedVector2Array([Vector2(20, 288), Vector2(34, 298), Vector2(38, 316), Vector2(24, 306)]), Color8(130, 181, 189))
	for k in range(4):
		draw_line(Vector2(23 + k * 0.6, 294 + k * 3), Vector2(33 + k * 0.6, 301 + k * 3), Color8(210, 228, 215), 1)
	draw_circle(Vector2(39, 318), 1, Color8(145, 230, 187))

	# Keyboard & Mouse
	draw_poly(PackedVector2Array([Vector2(46, 316), Vector2(55, 319), Vector2(64, 336), Vector2(54, 333)]), Color8(40, 58, 64), Color8(127, 145, 144))
	draw_oval(Vector2(68, 342), 3, 2, Color8(199, 206, 196))

	# Wheeled Office Swivel Chair
	draw_line(Vector2(99, 348), Vector2(99, 371), Color8(172, 184, 179), 3)
	for castor in [Vector2(81, 374), Vector2(109, 379), Vector2(117, 369), Vector2(92, 364), Vector2(97, 380)]:
		draw_line(Vector2(99, 371), castor, Color8(129, 152, 149), 2)
		draw_oval(castor + Vector2(0, 2), 3, 2, Color8(21, 42, 49))
	draw_poly(PackedVector2Array([Vector2(80, 340), Vector2(96, 334), Vector2(113, 342), Vector2(105, 354), Vector2(87, 351)]), Color8(56, 78, 88), Color8(110, 133, 136))
	draw_poly(PackedVector2Array([Vector2(106, 313), Vector2(116, 318), Vector2(115, 342), Vector2(105, 337)]), Color8(38, 62, 74), Color8(83, 108, 117))

	draw_canvas_text("PROGRAMOVANIE", Vector2(67, 395), Color8(192, 209, 190), 8, HORIZONTAL_ALIGNMENT_CENTER, true)

func draw_cnc_machine(p: Vector2, i: int, state: Dictionary) -> void:
	var modern: bool = (i == 6)
	var owned: bool = state.cncOwned[i]
	var power: bool = state.cncPower[i]
	var on: bool = (owned and power)
	var is_hover: bool = (hover_cnc == i)

	var s_x = 1.17 if modern else 1.0
	var s_y = 1.2 if modern else 1.0

	var origin = p

	# Floor shadow
	draw_oval(origin + Vector2(108 * s_x, 139 * s_y), 109 * s_x, 17 * s_y, Color(0.06, 0.16, 0.19, 0.4))

	var tf = func(local: Vector2) -> Vector2:
		return origin + Vector2(local.x * s_x, local.y * s_y)

	var poly_tf = func(pts: Array) -> PackedVector2Array:
		var arr = PackedVector2Array()
		for pt in pts:
			arr.append(origin + Vector2(pt[0] * s_x, pt[1] * s_y))
		return arr

	# 3D Roof and Right Wall
	var roof_pts = poly_tf.call([[0, 0], [19, -19], [211, -19], [192, 0]])
	draw_poly(roof_pts, Color8(228, 119, 112) if modern else Color8(208, 208, 183), Color8(151, 170, 160))

	var wall_pts = poly_tf.call([[192, 0], [211, -19], [211, 112], [192, 131]])
	draw_poly(wall_pts, Color8(134, 46, 58) if modern else Color8(62, 101, 92), Color8(107, 141, 127))

	# Machine Body
	var body_col = Color8(188, 66, 80) if modern else Color8(192, 195, 168)
	var base_col = Color8(143, 45, 59) if modern else Color8(66, 111, 95)
	draw_round_rect(Rect2(origin.x, origin.y, 192 * s_x, 130 * s_y), body_col, 3 * s_y)
	draw_round_rect(Rect2(origin.x, origin.y + 95 * s_y, 192 * s_x, 35 * s_y), base_col, 2 * s_y)
	draw_line(tf.call(Vector2(3, 2)), tf.call(Vector2(189, 2)), Color8(248, 161, 148) if modern else Color8(227, 228, 204), 2 * s_y)

	# Working Area Window & Spindle Chamber
	draw_round_rect(Rect2(origin.x + 8 * s_x, origin.y + 10 * s_y, 137 * s_x, 72 * s_y), Color8(155, 48, 63) if modern else Color8(167, 174, 149), 3 * s_y)
	draw_round_rect(Rect2(origin.x + 16 * s_x, origin.y + 18 * s_y, 121 * s_x, 54 * s_y), Color8(20, 46, 53), 3 * s_y)
	draw_round_rect(Rect2(origin.x + 21 * s_x, origin.y + 23 * s_y, 111 * s_x, 44 * s_y), Color8(47, 81, 85) if on else Color8(34, 59, 64), 2 * s_y)

	# Spindle / Chuck & Workpiece
	draw_round_rect(Rect2(origin.x + 25 * s_x, origin.y + 43 * s_y, 25 * s_x, 15 * s_y), Color8(131, 149, 144), 2 * s_y)
	draw_circle(tf.call(Vector2(49, 50)), 13 * s_y, Color8(108, 133, 129))
	draw_circle(tf.call(Vector2(49, 50)), 8 * s_y, Color8(182, 199, 188))
	draw_circle(tf.call(Vector2(49, 50)), 4 * s_y, Color8(32, 61, 64))
	draw_round_rect(Rect2(origin.x + 50 * s_x, origin.y + 45 * s_y, 55 * s_x, 10 * s_y), Color8(170, 188, 181), 2 * s_y)
	draw_line(tf.call(Vector2(51, 46)), tf.call(Vector2(103, 46)), Color8(214, 223, 202), 1)

	# Moving Tool Carriage with offset animation
	var offset = sin(time * 1.7 + float(i)) * 4.0 if on else 0.0
	draw_round_rect(Rect2(origin.x + (89.0 + offset) * s_x, origin.y + 29 * s_y, 21 * s_x, 9 * s_y), Color8(119, 141, 133), 1)
	var tool_tip_pts = poly_tf.call([[99 + offset, 38], [105 + offset, 38], [104 + offset, 48]])
	draw_poly(tool_tip_pts, Color8(215, 221, 198))
	draw_line(tf.call(Vector2(81, 26)), tf.call(Vector2(115, 26)), Color8(191, 186, 119), 2)
	draw_line(tf.call(Vector2(115, 26)), tf.call(Vector2(110, 41)), Color8(184, 186, 120), 2)

	# Sliding Door Rails
	draw_line(tf.call(Vector2(75, 16)), tf.call(Vector2(75, 73)), Color8(225, 107, 112) if modern else Color8(185, 193, 169), 3 * s_x)
	draw_round_rect(Rect2(origin.x + 132 * s_x, origin.y + 42 * s_y, 4 * s_x, 18 * s_y), Color8(221, 225, 208), 2)

	# Machine Control Screen & Keypad
	draw_round_rect(Rect2(origin.x + 147 * s_x, origin.y + 10 * s_y, 37 * s_x, 79 * s_y), Color8(237, 232, 219) if modern else Color8(200, 203, 179), 3 * s_y)
	draw_round_rect(Rect2(origin.x + 152 * s_x, origin.y + 18 * s_y, 27 * s_x, 23 * s_y), Color8(23, 47, 57), 2 * s_y)
	if on:
		draw_rect(Rect2(origin.x + 155 * s_x, origin.y + 22 * s_y, 20 * s_x, 3 * s_y), Color8(137, 198, 180))
		for k in range(3):
			draw_rect(Rect2(origin.x + 155 * s_x, origin.y + (28 + k * 3) * s_y, (11 + k * 3) * s_x, 1 * s_y), Color8(125, 174, 162))
	else:
		draw_line(tf.call(Vector2(155, 30)), tf.call(Vector2(175, 30)), Color8(71, 99, 103))

	for ky in range(49, 70, 8):
		for kx in range(153, 179, 8):
			draw_round_rect(Rect2(origin.x + kx * s_x, origin.y + ky * s_y, 4 * s_x, 4 * s_y), Color8(93, 117, 110), 1)
	draw_circle(tf.call(Vector2(166, 78)), 5 * s_y, Color8(185, 71, 62))
	draw_circle(tf.call(Vector2(166, 78)), 2 * s_y, Color8(232, 155, 110))

	# Retro Machine Industrial Coolant Patina
	if not modern:
		for k in range(12):
			var px = 12.0 + float((k * 47) % 129)
			var py = 75.0 + float((k * 19) % 38)
			draw_oval(tf.call(Vector2(px, py)), 4, 2, Color(0.48, 0.35, 0.23, 0.4))
		draw_round_rect(Rect2(origin.x + 16 * s_x, origin.y + 88 * s_y, 65 * s_x, 3 * s_y), Color(0.55, 0.39, 0.23, 0.44))

	# Machine Label Plate
	draw_round_rect(Rect2(origin.x + 12 * s_x, origin.y + 113 * s_y, 88 * s_x, 12 * s_y), Color8(118, 41, 54) if modern else Color8(49, 87, 71), 2 * s_y)
	draw_canvas_text("AMADA" if modern else "CNC " + str(i + 1), origin + Vector2(56 * s_x, 119 * s_y), Color8(255, 229, 221) if modern else Color8(229, 232, 204), 11 if modern else 12, HORIZONTAL_ALIGNMENT_CENTER, true)

	for k in range(5):
		draw_line(tf.call(Vector2(125, 105 + k * 4)), tf.call(Vector2(176, 105 + k * 4)), Color8(112, 35, 49) if modern else Color8(41, 78, 67), 2)
	for dx in [12.0, 169.0]:
		draw_round_rect(Rect2(origin.x + dx * s_x, origin.y + 130 * s_y, 9 * s_x, 10 * s_y), Color8(29, 52, 59))

	# Swarf Chute & Metal Chip Collection Bin
	var chute_pts = poly_tf.call([[179, 104], [202, 102], [224, 132], [209, 140]])
	draw_poly(chute_pts, Color8(84, 109, 101), Color8(158, 173, 156))
	var bin_box = Rect2(origin.x + 207 * s_x, origin.y + 142 * s_y, 33 * s_x, 23 * s_y)
	draw_round_rect(bin_box, Color8(54, 85, 102) if modern else Color8(98, 103, 75), 2)
	var bin_top = poly_tf.call([[203, 140], [232, 134], [241, 141], [211, 148]])
	draw_poly(bin_top, Color8(146, 155, 128))
	for k in range(8):
		var cx = 211.0 + float(k) * 3.0
		var cy = 139.0 + sin(float(k) * 3.0) * 2.0
		draw_line(tf.call(Vector2(cx, cy)), tf.call(Vector2(cx + 3, cy + 2)), Color8(192, 183, 155), 1)
	draw_circle(tf.call(Vector2(212, 167)), 3, Color8(29, 51, 56))
	draw_circle(tf.call(Vector2(234, 167)), 3, Color8(29, 51, 56))

	# Overhead Stack Light (Tower Light)
	draw_rect(Rect2(origin.x + 178 * s_x, origin.y - 33 * s_y, 4 * s_x, 17 * s_y), Color8(52, 78, 80))
	draw_round_rect(Rect2(origin.x + 171 * s_x, origin.y - 43 * s_y, 18 * s_x, 13 * s_y), Color8(37, 62, 67), 3)
	var light_col = Color8(114, 231, 168) if on else Color8(245, 118, 99)
	draw_round_rect(Rect2(origin.x + 173 * s_x, origin.y - 41 * s_y, 14 * s_x, 9 * s_y), light_col, 3)
	draw_glow(origin + Vector2(180 * s_x, -37 * s_y), 21, Color8(123, 242, 173) if on else Color8(249, 129, 100), 0.24)

	# Overlay if not owned
	if not owned:
		draw_round_rect(Rect2(origin.x, origin.y, 192 * s_x, 130 * s_y), Color8(16, 38, 50, 170), 3)
		draw_round_rect(Rect2(origin.x + 8 * s_x, origin.y + 46 * s_y, 176 * s_x, 42 * s_y), Color8(17, 38, 47, 237), 4)
		var price_text = "AMADA · ZAMKNUTÁ" if modern else "KÚPIŤ · " + str(FoundryEngine.cnc_price(i)) + " ₵"
		draw_canvas_text(price_text, origin + Vector2(96 * s_x, 68 * s_y), Color8(240, 211, 155), 13, HORIZONTAL_ALIGNMENT_CENTER, true)

	if is_hover:
		var h_rect = Rect2(origin.x - 6 * s_x, origin.y - 47 * s_y, 251 * s_x, 221 * s_y)
		draw_dash_line(h_rect.position, h_rect.position + Vector2(h_rect.size.x, 0), Color8(241, 212, 154), 2.0, 5.0, 5.0)
		draw_dash_line(h_rect.position + Vector2(h_rect.size.x, 0), h_rect.position + h_rect.size, Color8(241, 212, 154), 2.0, 5.0, 5.0)
		draw_dash_line(h_rect.position + h_rect.size, h_rect.position + Vector2(0, h_rect.size.y), Color8(241, 212, 154), 2.0, 5.0, 5.0)
		draw_dash_line(h_rect.position + Vector2(0, h_rect.size.y), h_rect.position, Color8(241, 212, 154), 2.0, 5.0, 5.0)
