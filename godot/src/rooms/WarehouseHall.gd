class_name WarehouseHall
extends "res://src/rooms/RoomRenderer.gd"

const BIN_POSITIONS = [
	Vector2(365, 330), Vector2(620, 330), Vector2(875, 330),
	Vector2(365, 555), Vector2(620, 555), Vector2(875, 555)
]
const BIN_IDS = ["iron", "steel", "copper", "tin", "zinc", "goods"]

var time: float = 0.0
var hover_bin: int = -1

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
		for i in range(BIN_POSITIONS.size()):
			var p = BIN_POSITIONS[i]
			var rect = Rect2(p.x - 85, p.y - 120, 170, 150)
			if rect.has_point(mouse_pos):
				found = i
				break
		if found != hover_bin:
			hover_bin = found
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hover_bin >= 0:
			var gm = get_node_or_null("/root/GameManager")
			if gm != null:
				gm.select_bin(BIN_IDS[hover_bin])

func _draw() -> void:
	var state = get_room_state()
	if state == null or state.is_empty():
		return

	var daylight = FoundryEngine.daylight(state)
	var night = 1.0 - daylight

	# Background gradient
	draw_rect(Rect2(0, 0, 1100, 690), Color8(44, 65, 70))
	draw_rect(Rect2(0, 0, 1100, 185), Color8(53, 71, 83))

	# Wall columns and windows
	for x in range(0, 1100, 138):
		draw_rect(Rect2(x, 0, 8, 185), Color8(24, 47, 57))
		draw_line(Vector2(x, 190), Vector2(x + 160, 690), Color(0.77, 0.81, 0.75, 0.07))
	for y in range(200, 690, 65):
		draw_line(Vector2(0, y), Vector2(1100, y), Color(0.72, 0.79, 0.69, 0.09))

	for x in range(250, 1100, 250):
		draw_round_rect(Rect2(x, 50, 165, 71), Color8(25, 52, 62), 3)
		var win_col = Color8(138, 174, 185) if daylight > 0.4 else Color8(38, 56, 81)
		draw_rect(Rect2(x + 5, 55, 155, 61), win_col)
		for j in range(1, 4):
			draw_line(Vector2(x + j * 41, 52), Vector2(x + j * 41, 120), Color8(54, 83, 93), 4)
		draw_line(Vector2(x, 87), Vector2(x + 165, 87), Color8(54, 83, 93), 4)

	draw_rect(Rect2(0, 181, 1100, 8), Color8(23, 47, 55))
	draw_pipe(0, 147, 1100, 7)
	draw_canvas_text("SKLADOVÁ HALA / PRÍJEM A EXPEDÍCIA", Vector2(650, 166), Color8(203, 215, 209), 13, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Receiving ramp on left
	draw_round_rect(Rect2(18, 206, 167, 328), Color8(21, 44, 53), 5)
	for y in range(212, 275, 10):
		draw_rect(Rect2(24, y, 155, 3), Color8(73, 100, 108))
	draw_rect(Rect2(25, 280, 151, 245), Color8(45, 69, 76))
	draw_dash_line(Vector2(198, 200), Vector2(198, 577), Color(0.88, 0.73, 0.44, 0.5), 3.0, 12.0, 9.0)
	draw_canvas_text("PRÍJMOVÁ RAMPA", Vector2(102, 298), Color8(237, 207, 149), 14, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Incoming materials list on ramp
	var mat_keys = Constants.MATERIALS.keys()
	for i in range(mat_keys.size()):
		var id = mat_keys[i]
		var mat = Constants.MATERIALS[id]
		var y = 334 + i * 36
		var qty = state.incoming.get(id, 0)
		draw_round_rect(Rect2(35, y + 13, 127, 5), Color8(170, 139, 91), 2)
		if qty > 0:
			draw_round_rect(Rect2(40, y - 7, 29, 21), Color.html(mat.color), 2)
			draw_line(Vector2(54, y - 7), Vector2(54, y + 14), Color8(48, 73, 81), 3)
			draw_canvas_text(mat.short + " · " + str(qty) + " kg", Vector2(80, y + 5), Color8(229, 236, 225), 11, HORIZONTAL_ALIGNMENT_LEFT)
		else:
			draw_canvas_text(mat.short + " · 0", Vector2(103, y + 5), Color8(114, 142, 151), 11)

	draw_canvas_text(str(FoundryEngine.used(state, "incoming")) + " / " + str(FoundryEngine.capacity(state, "incoming")) + " kg", Vector2(104, 555), Color8(231, 204, 162), 14, HORIZONTAL_ALIGNMENT_CENTER, true)

	# 6 3D Perspective Heavy Storage Bins
	for i in range(BIN_IDS.size()):
		draw_storage_bin(BIN_POSITIONS[i], BIN_IDS[i], i, state)

	# Storekeeper pushing pallet truck / trolley
	draw_storekeeper(state)

	# Night ambient & hall lights
	if night > 0.05:
		draw_rect(Rect2(0, 0, 1100, 690), Color(0.03, 0.07, 0.14, night * 0.23))
		for x in [365.0, 620.0, 875.0]:
			draw_round_rect(Rect2(x - 28, 30, 56, 9), Color8(35, 58, 66), 3)
			draw_round_rect(Rect2(x - 22, 39, 44, 3), Color8(217, 227, 203), 2)
			draw_glow(Vector2(x, 50), 80, Color8(223, 223, 186), 0.08 + night * 0.1)

func draw_storage_bin(p: Vector2, id: String, i: int, state: Dictionary) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var selected = (gm.selected_bin == id if gm != null else false)
	var over = (hover_bin == i)
	var raw = (id != "goods")
	var material = Constants.MATERIALS.get(id, null) if raw else null
	var count = state.raw.get(id, 0) if raw else FoundryEngine.used(state, "goods")
	var max_cap = FoundryEngine.bin_capacity(state, id) if raw else FoundryEngine.capacity(state, "goods")
	var color = Color.html(material.color) if raw else Color8(183, 213, 187)

	# Floor shadow
	draw_oval(p + Vector2(10, 16), 104, 24, Color(0.06, 0.15, 0.19, 0.33))
	var floor_border = PackedVector2Array([
		p + Vector2(-95, 16), p + Vector2(85, 16), p + Vector2(115, -8), p + Vector2(-65, -8)
	])
	draw_poly(floor_border, Color(0.90, 0.75, 0.52, 0.09) if selected else Color(0.76, 0.80, 0.73, 0.03), Color8(228, 197, 139) if selected else Color(0.55, 0.64, 0.63, 0.29))

	# 3D Rack Perspective Structure
	draw_round_rect(Rect2(p.x - 77, p.y - 103, 156, 111), Color8(48, 73, 82), 4)
	var right_face = PackedVector2Array([
		p + Vector2(79, -103), p + Vector2(100, -121), p + Vector2(100, -10), p + Vector2(79, 8)
	])
	draw_poly(right_face, Color8(33, 59, 69), Color8(82, 107, 112))

	var top_face = PackedVector2Array([
		p + Vector2(-77, -103), p + Vector2(-56, -121), p + Vector2(100, -121), p + Vector2(79, -103)
	])
	draw_poly(top_face, Color8(113, 131, 126), Color8(152, 165, 155))

	draw_round_rect(Rect2(p.x - 70, p.y - 92, 142, 91), Color8(20, 47, 57), 2)
	for dx in [-79.0, 73.0]:
		draw_rect(Rect2(p.x + dx, p.y - 112, 8, 126), Color8(127, 153, 147))

	# Wooden Shelves
	for shelf_y in [-47.0, -8.0]:
		draw_round_rect(Rect2(p.x - 77, p.y + shelf_y, 155, 8), Color8(187, 162, 115), 2)
		draw_line(p + Vector2(-73, shelf_y + 2), p + Vector2(73, shelf_y + 2), Color8(236, 213, 160))

	# Stock Items stacked on shelves
	if raw:
		var total = mini(12, int(ceil(float(count) / maxf(1.0, float(max_cap)) * 12.0)))
		for j in range(total):
			var sx = p.x - 62.0 + float(j % 6) * 22.0
			var sy = p.y + (-57.0 if j < 6 else -18.0)
			draw_round_rect(Rect2(sx, sy - 28, 18, 25), color, 2)
			var ingot_top = PackedVector2Array([
				Vector2(sx, sy - 28), Vector2(sx + 5, sy - 34), Vector2(sx + 23, sy - 34), Vector2(sx + 18, sy - 28)
			])
			draw_poly(ingot_top, Color(0.77, 0.82, 0.76, 0.27))
			draw_line(Vector2(sx + 9, sy - 27), Vector2(sx + 9, sy - 5), Color8(44, 68, 75), 2)
	else:
		var j = 0
		for prod_key in state.goods.keys():
			var n = int(state.goods[prod_key])
			for k in range(mini(4, n)):
				if j >= 12:
					break
				var sx = p.x - 56.0 + float(j % 6) * 24.0
				var sy = p.y + (-59.0 if j < 6 else -20.0)
				var fill_col = Color.html(Constants.PRODUCTS[prod_key].color)
				draw_round_rect(Rect2(sx - 9, sy - 20, 18, 20), fill_col, 2)
				draw_circle(Vector2(sx, sy), 9, fill_col)
				draw_circle(Vector2(sx, sy), 3.0 if prod_key == "bronze_bushing" else 6.0, Color8(23, 50, 59))
				j += 1

	# Header label
	var label = material.name if raw else "Hotové výrobky"
	draw_round_rect(Rect2(p.x - 99, p.y - 149, 210, 31), Color8(22, 47, 57, 239), 5)
	draw_canvas_text(label, Vector2(p.x + 6, p.y - 133), Color8(255, 226, 166) if selected else Color8(214, 227, 224), 14, HORIZONTAL_ALIGNMENT_CENTER, true)

	var is_open = FoundryEngine.bin_open(state, id) if raw else true
	var count_str = ("ZAMKNUTÉ · " + str(Constants.BIN_UNLOCK[id]) + " ₵") if (raw and not is_open) else (str(count) + " / " + str(max_cap) + (" kg" if raw else " ks"))
	draw_canvas_text(count_str, Vector2(p.x + 3, p.y + 26), color, 13 if (raw and not is_open) else 18, HORIZONTAL_ALIGNMENT_CENTER, true)

	# Fill bar
	var fill_pr = clampf(float(count) / maxf(1.0, float(max_cap)), 0.0, 1.0)
	draw_round_rect(Rect2(p.x - 74, p.y + 42, 154, 4), Color8(20, 46, 56), 2)
	draw_round_rect(Rect2(p.x - 74, p.y + 42, 154 * fill_pr, 4), color, 2)

	if raw and state.incoming.get(id, 0) > 0:
		draw_round_rect(Rect2(p.x - 76, p.y + 51, 161, 20), Color8(89, 73, 51), 4)
		draw_canvas_text("NA RAMPE: " + str(state.incoming[id]) + " kg", Vector2(p.x + 5, p.y + 61), Color8(255, 225, 167), 11)

	if selected or over:
		var b_rect = Rect2(p.x - 104, p.y - 158, 218, 236)
		draw_dash_line(b_rect.position, b_rect.position + Vector2(b_rect.size.x, 0), Color8(244, 206, 136) if selected else Color8(180, 199, 183), 2.0, 5.0, 5.0)
		draw_dash_line(b_rect.position + Vector2(b_rect.size.x, 0), b_rect.position + b_rect.size, Color8(244, 206, 136) if selected else Color8(180, 199, 183), 2.0, 5.0, 5.0)
		draw_dash_line(b_rect.position + b_rect.size, b_rect.position + Vector2(0, b_rect.size.y), Color8(244, 206, 136) if selected else Color8(180, 199, 183), 2.0, 5.0, 5.0)
		draw_dash_line(b_rect.position + Vector2(0, b_rect.size.y), b_rect.position, Color8(244, 206, 136) if selected else Color8(180, 199, 183), 2.0, 5.0, 5.0)

func draw_storekeeper(state: Dictionary) -> void:
	var move = state.get("stockMove", null)
	var age = (state.clock - float(move.at)) if (move != null and move.has("at")) else 5.0
	var storekeeper = FoundryEngine.profile(FoundryEngine.duty(state, "warehouse"))
	if storekeeper == null or storekeeper.is_empty():
		return

	if move != null and age >= 0.0 and age < 3.0:
		# Pushing trolley from loading dock to bin
		var mat_idx = Constants.MATERIALS.keys().find(move.get("material", "iron"))
		if mat_idx >= 0 and mat_idx < BIN_POSITIONS.size():
			var target = BIN_POSITIONS[mat_idx]
			var p = age / 3.0
			var x = 150.0 + (target.x - 150.0) * p
			var y = 553.0 + (target.y + 25.0 - 553.0) * p

			# Pallet cart / trolley
			draw_round_rect(Rect2(x - 20, y - 12, 48, 7), Color8(195, 155, 87), 2)
			draw_circle(Vector2(x - 13, y), 5, Color8(25, 47, 53))
			draw_circle(Vector2(x + 23, y), 5, Color8(25, 47, 53))
			var mat_color = Color.html(Constants.MATERIALS[move.material].color)
			draw_round_rect(Rect2(x - 14, y - 40, 35, 28), mat_color, 3)
			draw_line(Vector2(x - 22, y - 12), Vector2(x - 39, y - 39), Color8(200, 187, 139), 3)

			draw_worker(Vector2(x - 61, y + 3), false, 1.0, false, 1.0, storekeeper, time)
			draw_canvas_text("+" + str(move.quantity) + " kg", Vector2(x, y - 53), Color8(255, 229, 185), 13, HORIZONTAL_ALIGNMENT_CENTER, true)
			draw_canvas_text(storekeeper.get("name", "Skladník"), Vector2(x - 61, y + 18), Color8(219, 235, 218), 10)
	else:
		# Regular patrol
		var phase = fmod(time, 28.0)
		var progress = (phase / 12.0) if phase < 12.0 else (1.0 if phase < 14.0 else ((1.0 - (phase - 14.0) / 12.0) if phase < 26.0 else 0.0))
		var x = 275.0 + progress * 730.0
		var y = 635.0
		var walk = 1.0 if (phase < 12.0 or (phase >= 14.0 and phase < 26.0)) else 0.0
		var facing = 1.0 if phase < 14.0 else -1.0
		draw_worker(Vector2(x, y), false, walk, false, facing, storekeeper, time)
		draw_round_rect(Rect2(x - 59, y + 8, 118, 19), Color8(24, 50, 60, 232), 4)
		draw_canvas_text(storekeeper.get("name", "Skladník") + " · SKLADNÍK", Vector2(x, y + 18), Color8(217, 229, 206), 10, HORIZONTAL_ALIGNMENT_CENTER, true)
