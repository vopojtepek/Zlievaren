class_name RoomRenderer
extends Node2D

const FONT_REGULAR = preload("res://assets/fonts/DMSans.ttf")
const FONT_BOLD = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")

var current_state: Dictionary = {}
static var glow_texture: GradientTexture2D
static var gradients: Dictionary = {}

func draw_gradient_rect(rect: Rect2, colors: PackedColorArray, stops: PackedFloat32Array) -> void:
	var key = str(colors) + str(stops)
	if not gradients.has(key):
		var gradient = Gradient.new()
		gradient.colors = colors
		gradient.offsets = stops
		var texture = GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 4
		texture.height = 512
		texture.fill_from = Vector2.ZERO
		texture.fill_to = Vector2(0, 1)
		gradients[key] = texture
	draw_texture_rect(gradients[key], rect, false)

func get_room_state() -> Dictionary:
	if not current_state.is_empty():
		return current_state
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and gm.get("state") != null:
		return gm.state
	return {}

static func heat_color(temp: float) -> Color:
	var points = [
		[20.0, Color8(82, 102, 107)],
		[400.0, Color8(109, 61, 51)],
		[650.0, Color8(184, 53, 33)],
		[900.0, Color8(247, 96, 38)],
		[1150.0, Color8(255, 157, 67)],
		[1450.0, Color8(255, 233, 164)]
	]
	if temp <= points[0][0]:
		return points[0][1]
	for i in range(1, points.size()):
		if temp <= points[i][0]:
			var a = points[i - 1]
			var b = points[i]
			var f = clampf((temp - a[0]) / (b[0] - a[0]), 0.0, 1.0)
			return a[1].lerp(b[1], f)
	return Color8(255, 233, 164)

func draw_round_rect(r: Rect2, color: Color, radius: float = 0.0) -> void:
	if radius <= 0.0:
		draw_rect(r, color)
		return
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.set_corner_radius_all(int(radius))
	draw_style_box(style_box, r)

func draw_poly(points: PackedVector2Array, fill: Color, stroke: Color = Color.TRANSPARENT, stroke_width: float = 1.0) -> void:
	if fill.a > 0.0 and points.size() >= 3:
		draw_colored_polygon(points, fill)
	if stroke.a > 0.0 and points.size() >= 2:
		var closed = points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, stroke, stroke_width)

func draw_circ(pos: Vector2, r: float, fill: Color, stroke: Color = Color.TRANSPARENT, stroke_width: float = 1.0) -> void:
	if fill.a > 0.0:
		draw_circle(pos, r, fill)
	if stroke.a > 0.0:
		draw_arc(pos, r, 0.0, TAU, 32, stroke, stroke_width)

func draw_oval(center: Vector2, rx: float, ry: float, fill: Color, stroke: Color = Color.TRANSPARENT, stroke_width: float = 1.0, segments: int = 24) -> void:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = float(i) * TAU / float(segments)
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	if fill.a > 0.0:
		draw_colored_polygon(points, fill)
	if stroke.a > 0.0:
		var closed = points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, stroke, stroke_width)

func draw_dash_line(from: Vector2, to: Vector2, color: Color, width: float = 1.0, dash: float = 6.0, gap: float = 5.0) -> void:
	var total_dist = from.distance_to(to)
	if total_dist <= 0.001:
		return
	var dir = (to - from).normalized()
	var curr: float = 0.0
	while curr < total_dist:
		var end_seg = minf(curr + dash, total_dist)
		draw_line(from + dir * curr, from + dir * end_seg, color, width)
		curr += dash + gap

func draw_canvas_text(str_val: String, pos: Vector2, color: Color = Color8(198, 215, 204), size: int = 12, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, bold: bool = false) -> void:
	var font = FONT_BOLD if bold else FONT_REGULAR
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		var approx_width = font.get_string_size(str_val, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, Vector2(pos.x - approx_width * 0.5, pos.y + float(size) * 0.35), str_val, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		var approx_width = font.get_string_size(str_val, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, Vector2(pos.x - approx_width, pos.y + float(size) * 0.35), str_val, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	else:
		draw_string(font, Vector2(pos.x, pos.y + float(size) * 0.35), str_val, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_glow(pos: Vector2, radius: float, color: Color, alpha: float = 1.0) -> void:
	if alpha <= 0.0:
		return
	if glow_texture == null:
		var gradient = Gradient.new()
		gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
		glow_texture = GradientTexture2D.new()
		glow_texture.gradient = gradient
		glow_texture.width = 128
		glow_texture.height = 128
		glow_texture.fill = GradientTexture2D.FILL_RADIAL
		glow_texture.fill_from = Vector2(0.5, 0.5)
		glow_texture.fill_to = Vector2(1, 0.5)
	var c = color
	c.a = alpha
	draw_texture_rect(glow_texture, Rect2(pos - Vector2.ONE * radius, Vector2.ONE * radius * 2), false, c)

func draw_pipe(x: float, y: float, w: float, h: float) -> void:
	draw_round_rect(Rect2(x + 4, y + 5, w, h), Color8(21, 35, 39), 4)
	draw_round_rect(Rect2(x, y, w, h), Color8(87, 106, 104), 4)
	draw_round_rect(Rect2(x + 2, y + 2, w - 4, 3), Color8(131, 145, 138), 2)
	var i = 25.0
	while i < w:
		draw_round_rect(Rect2(x + i, y - 3, 7, h + 6), Color8(58, 77, 77), 2)
		i += 100.0

func draw_stream(from: Vector2, to: Vector2, width: float = 5.0, time_val: float = 0.0) -> void:
	var mid = Vector2((from.x + to.x) * 0.5, from.y + 3.0)
	var curve_pts = PackedVector2Array()
	var steps = 16
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var p = (1.0 - t) * (1.0 - t) * from + 2.0 * (1.0 - t) * t * mid + t * t * to
		curve_pts.append(p)
	draw_polyline(curve_pts, Color8(255, 154, 59), width)
	draw_polyline(curve_pts, Color8(255, 241, 184), width * 0.35)
	for k in range(5):
		var a = fmod(time_val * 1.7 + float(k) * 0.2, 1.0)
		var spark_p = Vector2(to.x + sin(float(k) * 2.3) * a * 17.0, to.y - a * 18.0 + a * a * 15.0)
		draw_circle(spark_p, (1.0 - a) * 1.6 + 0.4, Color8(255, 214, 147))

func draw_worker(pos: Vector2, small: bool = false, walk: float = 0.0, handling: bool = false, facing: float = 1.0, crew: Dictionary = {}, time_val: float = 0.0) -> void:
	var crew_color = Color.html(crew.get("color", "#385f57"))
	var helmet_color = Color.html(crew.get("helmet", "#d9a842"))
	var scale_factor = (0.85 if small else (1.45 if handling else 1.0))
	var s_x = scale_factor * facing
	var s_y = scale_factor
	var step = sin(time_val * 11.0) * 5.0 if (walk > 0.0) else 0.0

	# Ground shadow
	draw_oval(pos + Vector2(0, 4.0 * s_y), 17.0 * scale_factor, 6.0 * scale_factor, Color(0.08, 0.16, 0.17, 0.33))

	# Helper lambda for local coordinate transform
	var tf = func(local: Vector2) -> Vector2:
		return pos + Vector2(local.x * s_x, local.y * s_y)

	# Legs & Boots
	draw_line(tf.call(Vector2(-6, -19)), tf.call(Vector2(-8 + step, 0)), Color8(32, 57, 56), 8.0 * scale_factor)
	draw_line(tf.call(Vector2(6, -19)), tf.call(Vector2(8 - step, 0)), Color8(32, 57, 56), 8.0 * scale_factor)
	draw_round_rect(Rect2(pos.x + (-13.0 + step) * s_x if s_x > 0 else pos.x + (-1.0 + step) * s_x, pos.y + (-2.0) * s_y, 12.0 * scale_factor, 6.0 * scale_factor), Color8(23, 46, 48), 2.0 * scale_factor)
	draw_round_rect(Rect2(pos.x + (3.0 - step) * s_x if s_x > 0 else pos.x + (15.0 - step) * s_x, pos.y + (-2.0) * s_y, 12.0 * scale_factor, 6.0 * scale_factor), Color8(23, 46, 48), 2.0 * scale_factor)

	# Body & Overalls
	var body_x = pos.x - 12.0 * s_x if s_x > 0 else pos.x + 13.0 * s_x
	draw_round_rect(Rect2(pos.x - 12.0 * scale_factor, pos.y - 38.0 * s_y, 25.0 * scale_factor, 25.0 * scale_factor), crew_color, 5.0 * scale_factor)
	draw_round_rect(Rect2(pos.x - 15.0 * scale_factor, pos.y - 37.0 * s_y, 6.0 * scale_factor, 18.0 * scale_factor), crew_color, 3.0 * scale_factor)

	# Arm & Tool
	var arm_end_x = 25.0 if handling else 16.0
	var arm_end_y = -32.0 if handling else -18.0
	draw_line(tf.call(Vector2(13, -34)), tf.call(Vector2(arm_end_x, arm_end_y)), Color8(209, 164, 101), 6.0 * scale_factor)
	draw_rect(Rect2(pos.x - 10.0 * scale_factor, pos.y - 27.0 * s_y, 22.0 * scale_factor, 3.0 * scale_factor), Color8(233, 214, 169))
	draw_rect(Rect2(pos.x - 3.0 * scale_factor, pos.y - 37.0 * s_y, 6.0 * scale_factor, 23.0 * scale_factor), Color8(208, 166, 107))

	# Head & Helmet
	draw_circle(tf.call(Vector2(1, -45)), 10.0 * scale_factor, Color8(202, 185, 149))
	draw_round_rect(Rect2(pos.x - 12.0 * scale_factor, pos.y - 50.0 * s_y, 27.0 * scale_factor, 6.0 * scale_factor), helmet_color, 3.0 * scale_factor)
	draw_circle(tf.call(Vector2(1, -52)), 10.0 * scale_factor, helmet_color)
	draw_rect(Rect2(pos.x - 9.0 * scale_factor, pos.y - 49.0 * s_y, 21.0 * scale_factor, 3.0 * scale_factor), Color8(241, 209, 122))
	draw_round_rect(Rect2(pos.x - 5.0 * scale_factor, pos.y - 45.0 * s_y, 14.0 * scale_factor, 4.0 * scale_factor), Color8(66, 88, 80), 2.0 * scale_factor)

func draw_foreman(pos: Vector2, master: Dictionary, time_val: float, facing: float, step: float, walking: bool) -> void:
	var master_index: int = int(master.get("appearance", 0))
	var s_x = 1.12 * facing
	var s_y = 1.12
	var bounce = -abs(sin(time_val * 13.0)) * 0.9 if walking else 0.0

	var origin = pos + Vector2(0, bounce)

	# Shadow
	draw_oval(pos + Vector2(0, 3), 24, 7, Color(0.06, 0.13, 0.16, 0.44))

	var tf = func(local: Vector2) -> Vector2:
		return origin + Vector2(local.x * s_x, local.y * s_y)

	var poly_tf = func(pts: Array) -> PackedVector2Array:
		var arr = PackedVector2Array()
		for p in pts:
			arr.append(origin + Vector2(p[0] * s_x, p[1] * s_y))
		return arr

	if master_index == 0:
		# --- MIŠO (Day shift: black hoodie with hood down, silver thorn print, long dark hair, full beard) ---
		# Legs
		draw_line(tf.call(Vector2(-6, -21)), tf.call(Vector2(-8 + step, 0)), Color8(17, 21, 27), 9.0 * s_y)
		draw_line(tf.call(Vector2(6, -21)), tf.call(Vector2(8 - step, 0)), Color8(23, 27, 33), 9.0 * s_y)
		draw_line(tf.call(Vector2(-8, -19)), tf.call(Vector2(-9 + step, -4)), Color8(54, 59, 67), 1.2 * s_y)
		draw_line(tf.call(Vector2(8, -19)), tf.call(Vector2(9 - step, -4)), Color8(54, 59, 67), 1.2 * s_y)
		# Boots
		draw_round_rect(Rect2(origin.x + (-15.0 + step) * s_x if s_x > 0 else origin.x + step * s_x, origin.y + (-2.0) * s_y, 15.0 * 1.12, 6.0 * s_y), Color8(10, 16, 22), 2.0 * s_y)
		draw_round_rect(Rect2(origin.x + (3.0 - step) * s_x if s_x > 0 else origin.x + (18.0 - step) * s_x, origin.y + (-2.0) * s_y, 15.0 * 1.12, 6.0 * s_y), Color8(10, 16, 22), 2.0 * s_y)
		draw_line(tf.call(Vector2(-14 + step, 3)), tf.call(Vector2(-1 + step, 3)), Color8(97, 112, 120), 1.0)
		draw_line(tf.call(Vector2(4 - step, 3)), tf.call(Vector2(17 - step, 3)), Color8(97, 112, 120), 1.0)

		# Arms & Sleeves
		draw_line(tf.call(Vector2(-13, -39)), tf.call(Vector2(-16 - step * 0.65, -19)), Color8(16, 20, 26), 9.0 * s_y)
		draw_line(tf.call(Vector2(13, -39)), tf.call(Vector2(17 + step * 0.65, -20)), Color8(32, 37, 45), 9.0 * s_y)
		draw_circle(tf.call(Vector2(-16 - step * 0.65, -17)), 3.0 * s_y, Color8(194, 157, 124))
		draw_circle(tf.call(Vector2(17 + step * 0.65, -18)), 3.0 * s_y, Color8(194, 157, 124))

		# Torso & Loose Hoodie
		draw_round_rect(Rect2(origin.x - 14.0 * 1.12, origin.y - 43.0 * s_y, 29.0 * 1.12, 28.0 * s_y), Color8(18, 22, 28), 6.0 * s_y)
		draw_line(tf.call(Vector2(-13, -36)), tf.call(Vector2(-12, -20)), Color8(75, 83, 93), 1.0)
		draw_line(tf.call(Vector2(14, -36)), tf.call(Vector2(13, -20)), Color8(73, 81, 90), 1.0)
		draw_round_rect(Rect2(origin.x - 10.0 * 1.12, origin.y - 21.0 * s_y, 20.0 * 1.12, 3.0 * s_y), Color8(36, 43, 52), 2.0 * s_y)

		# Hood resting down around neck
		draw_oval(tf.call(Vector2(0, -43)), 16.0 * 1.12, 10.0 * s_y, Color8(41, 44, 50), Color8(83, 88, 98), 1.0)
		draw_oval(tf.call(Vector2(0, -44)), 11.0 * 1.12, 6.0 * s_y, Color8(16, 20, 25))

		# Silver Thorn-like Black-Metal Print
		for side in [-1.0, 1.0]:
			draw_line(tf.call(Vector2(side * 2.0, -33)), tf.call(Vector2(side * 11.0, -37)), Color8(196, 201, 202), 1.0)
			draw_line(tf.call(Vector2(side * 4.0, -31)), tf.call(Vector2(side * 11.0, -30)), Color8(226, 230, 223), 1.0)
			draw_line(tf.call(Vector2(side * 7.0, -35)), tf.call(Vector2(side * 10.0, -41)), Color8(196, 201, 202), 0.8)
			draw_line(tf.call(Vector2(side * 7.0, -32)), tf.call(Vector2(side * 11.0, -27)), Color8(196, 201, 202), 0.8)
		draw_line(tf.call(Vector2(-5, -24)), tf.call(Vector2(5, -24)), Color8(151, 159, 159), 1.0)
		draw_line(tf.call(Vector2(-6, -40)), tf.call(Vector2(-7, -34)), Color8(181, 185, 185), 0.8)
		draw_line(tf.call(Vector2(7, -40)), tf.call(Vector2(8, -34)), Color8(181, 185, 185), 0.8)

		# Dark brown hair hanging over both shoulders
		draw_oval(tf.call(Vector2(0, -51)), 13.0 * 1.12, 14.0 * s_y, Color8(32, 28, 28))
		draw_poly(poly_tf.call([[-12, -53], [-14, -37], [-10, -30], [-6, -34], [-6, -55]]), Color8(41, 32, 32))
		draw_poly(poly_tf.call([[8, -55], [13, -51], [15, -32], [10, -29], [6, -40]]), Color8(35, 30, 31))
		# Face
		draw_oval(tf.call(Vector2(1, -49)), 8.0 * 1.12, 10.0 * s_y, Color8(198, 161, 130))
		draw_poly(poly_tf.call([[-9, -57], [-2, -64], [8, -60], [12, -53], [7, -51], [4, -57], [-4, -51], [-8, -45]]), Color8(33, 29, 30))
		draw_line(tf.call(Vector2(-11, -52)), tf.call(Vector2(-11, -35)), Color8(73, 53, 46), 1.3)
		draw_line(tf.call(Vector2(11, -51)), tf.call(Vector2(12, -34)), Color8(73, 54, 46), 1.0)
		# Eyes & nose
		draw_line(tf.call(Vector2(-5, -50)), tf.call(Vector2(-1, -50)), Color8(23, 29, 36), 1.4)
		draw_line(tf.call(Vector2(4, -50)), tf.call(Vector2(8, -50)), Color8(23, 29, 36), 1.4)
		draw_line(tf.call(Vector2(2, -49)), tf.call(Vector2(3, -45)), Color8(152, 119, 88), 1.0)

		# Beard reaching chest
		draw_poly(poly_tf.call([[-7, -46], [-3, -44], [2, -45], [6, -44], [10, -46], [9, -35], [5, -25], [1, -22], [-4, -29], [-8, -36]]), Color8(11, 16, 22))
		draw_line(tf.call(Vector2(-4, -39)), tf.call(Vector2(-1, -27)), Color8(44, 48, 54), 1.0)
		draw_line(tf.call(Vector2(6, -40)), tf.call(Vector2(4, -30)), Color8(45, 48, 54), 1.0)
		draw_line(tf.call(Vector2(-4, -44)), tf.call(Vector2(1, -45)), Color8(10, 16, 22), 2.0)
		draw_line(tf.call(Vector2(1, -45)), tf.call(Vector2(7, -43)), Color8(10, 16, 22), 2.0)

	else:
		# --- MIRO (Night shift: grey trousers, blue hoodie, round clean-shaven bald face) ---
		# Legs
		draw_line(tf.call(Vector2(-7, -21)), tf.call(Vector2(-9 + step, 0)), Color8(114, 123, 133), 10.0 * s_y)
		draw_line(tf.call(Vector2(7, -21)), tf.call(Vector2(9 - step, 0)), Color8(147, 154, 161), 10.0 * s_y)
		draw_line(tf.call(Vector2(-9, -18)), tf.call(Vector2(-11 + step, -5)), Color8(176, 181, 184), 1.0)
		draw_line(tf.call(Vector2(9, -18)), tf.call(Vector2(10 - step, -5)), Color8(195, 198, 198), 1.0)
		# Boots
		draw_round_rect(Rect2(origin.x + (-16.0 + step) * s_x if s_x > 0 else origin.x + step * s_x, origin.y + (-2.0) * s_y, 16.0 * 1.12, 6.0 * s_y), Color8(29, 41, 51), 2.0 * s_y)
		draw_round_rect(Rect2(origin.x + (4.0 - step) * s_x if s_x > 0 else origin.x + (20.0 - step) * s_x, origin.y + (-2.0) * s_y, 16.0 * 1.12, 6.0 * s_y), Color8(24, 39, 48), 2.0 * s_y)
		draw_line(tf.call(Vector2(-15 + step, 3)), tf.call(Vector2(-2 + step, 3)), Color8(138, 153, 159), 1.0)
		draw_line(tf.call(Vector2(5 - step, 3)), tf.call(Vector2(18 - step, 3)), Color8(138, 153, 159), 1.0)

		# Blue Sleeves & Hands
		draw_line(tf.call(Vector2(-15, -38)), tf.call(Vector2(-18 - step * 0.65, -19)), Color8(53, 105, 155), 10.0 * s_y)
		draw_line(tf.call(Vector2(15, -38)), tf.call(Vector2(19 + step * 0.65, -20)), Color8(86, 143, 193), 10.0 * s_y)
		draw_circle(tf.call(Vector2(-18 - step * 0.65, -17)), 3.5 * s_y, Color8(219, 179, 149))
		draw_circle(tf.call(Vector2(19 + step * 0.65, -18)), 3.5 * s_y, Color8(219, 179, 149))

		# Blue Hoodie Body
		draw_round_rect(Rect2(origin.x - 17.0 * 1.12, origin.y - 44.0 * s_y, 35.0 * 1.12, 30.0 * s_y), Color8(57, 123, 174), 7.0 * s_y)
		draw_line(tf.call(Vector2(-15, -36)), tf.call(Vector2(-14, -20)), Color8(131, 184, 215), 1.3)
		draw_line(tf.call(Vector2(16, -36)), tf.call(Vector2(15, -20)), Color8(99, 158, 199), 1.3)
		draw_round_rect(Rect2(origin.x - 12.0 * 1.12, origin.y - 19.0 * s_y, 25.0 * 1.12, 4.0 * s_y), Color8(44, 102, 151), 2.0 * s_y)

		# Hood
		draw_oval(tf.call(Vector2(0, -43)), 17.0 * 1.12, 10.0 * s_y, Color8(85, 140, 182), Color8(137, 184, 212), 1.0)
		draw_oval(tf.call(Vector2(0, -44)), 11.0 * 1.12, 6.0 * s_y, Color8(36, 87, 127))

		# Kangaroo pocket & strings
		draw_poly(poly_tf.call([[-9, -28], [-5, -33], [6, -33], [10, -28], [9, -22], [-8, -22]]), Color8(48, 106, 155), Color8(104, 154, 192), 1.0)
		draw_line(tf.call(Vector2(-6, -41)), tf.call(Vector2(-7, -33)), Color8(208, 217, 211), 1.0)
		draw_line(tf.call(Vector2(7, -41)), tf.call(Vector2(8, -33)), Color8(208, 217, 211), 1.0)

		# Bald Clean-Shaven Face & Features
		draw_round_rect(Rect2(origin.x - 5.0 * 1.12, origin.y - 44.0 * s_y, 12.0 * 1.12, 7.0 * s_y), Color8(205, 165, 135), 3.0 * s_y)
		draw_oval(tf.call(Vector2(-12, -50)), 3.0 * 1.12, 5.0 * s_y, Color8(197, 154, 128))
		draw_oval(tf.call(Vector2(13, -50)), 3.0 * 1.12, 5.0 * s_y, Color8(212, 173, 144))
		draw_oval(tf.call(Vector2(0, -52)), 13.0 * 1.12, 15.0 * s_y, Color8(222, 181, 150))
		draw_oval(tf.call(Vector2(-8, -46)), 6.0 * 1.12, 7.0 * s_y, Color8(222, 177, 148))
		draw_oval(tf.call(Vector2(8, -46)), 6.0 * 1.12, 7.0 * s_y, Color8(230, 186, 155))
		draw_oval(tf.call(Vector2(-3, -61)), 6.0 * 1.12, 3.0 * s_y, Color8(237, 201, 169))
		# Eyes, brows, nose
		draw_line(tf.call(Vector2(-8, -55)), tf.call(Vector2(-3, -55)), Color8(143, 113, 93), 1.3)
		draw_line(tf.call(Vector2(3, -55)), tf.call(Vector2(8, -55)), Color8(143, 113, 93), 1.3)
		draw_circle(tf.call(Vector2(-5, -52)), 1.1 * s_y, Color8(48, 60, 67))
		draw_circle(tf.call(Vector2(6, -52)), 1.1 * s_y, Color8(48, 60, 67))
		draw_line(tf.call(Vector2(1, -51)), tf.call(Vector2(2, -47)), Color8(182, 140, 113), 1.2)
		draw_oval(tf.call(Vector2(2, -46)), 2.5 * 1.12, 1.5 * s_y, Color8(211, 162, 135))
		draw_oval(tf.call(Vector2(-8, -47)), 3.5 * 1.12, 2.0 * s_y, Color8(223, 168, 142))
		draw_oval(tf.call(Vector2(8, -47)), 3.5 * 1.12, 2.0 * s_y, Color8(228, 171, 143))
		draw_line(tf.call(Vector2(-3, -42)), tf.call(Vector2(5, -42)), Color8(167, 117, 101), 1.1)
		draw_oval(tf.call(Vector2(1, -39)), 5.0 * 1.12, 2.0 * s_y, Color8(227, 187, 157))

	# Name Badge underneath
	var master_name = master.get("name", "Majster")
	draw_round_rect(Rect2(pos.x - 56, pos.y + 8, 112, 17), Color8(18, 30, 39, 239), 4)
	var badge_col = Color8(194, 224, 251) if master_index > 0 else Color8(224, 207, 176)
	draw_canvas_text(master_name, Vector2(pos.x, pos.y + 16.5), badge_col, 10, HORIZONTAL_ALIGNMENT_CENTER, true)
