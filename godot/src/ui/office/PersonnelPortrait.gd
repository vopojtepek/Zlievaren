extends Control
## Stable, code-drawn ink portrait. No simulation RNG or saved appearance data.
var identity: int = 0
var role: String = ""
const INK = Color("514a3d")

func configure(person_name: String, profession: String) -> void:
	role = profession
	identity = (person_name + ":" + role).hash()
	custom_minimum_size = Vector2(100, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func line(points: Array, color: Color = INK, width: float = 1.4) -> void:
	draw_polyline(PackedVector2Array(points), color, width, true)

func _draw() -> void:
	draw_rect(Rect2(1, 1, 98, 118), Color("e5d9bc"))
	draw_rect(Rect2(1, 1, 98, 118), Color("b8a989"), false)
	var jaw: float = 3.0 + identity % 5
	var face = [Vector2(32, 34), Vector2(68, 34), Vector2(67, 59), Vector2(58 + jaw, 72), Vector2(44, 76), Vector2(32, 60), Vector2(32, 34)]
	draw_colored_polygon(PackedVector2Array(face), Color("f4e9ce"))
	line(face)
	line([Vector2(39, 74), Vector2(38, 83), Vector2(17, 91), Vector2(9, 116), Vector2(91, 116), Vector2(82, 91), Vector2(61, 82), Vector2(60, 72)])
	line([Vector2(38, 82), Vector2(50, 94), Vector2(61, 82)])
	line([Vector2(30, 87), Vector2(39, 101), Vector2(50, 94), Vector2(61, 101), Vector2(70, 87)])
	line([Vector2(50, 95), Vector2(50, 116)])
	line([Vector2(38, 46), Vector2(44, 45)])
	line([Vector2(56, 45), Vector2(62, 46)])
	draw_circle(Vector2(41, 49), 1.3, INK)
	draw_circle(Vector2(59, 49), 1.3, INK)
	line([Vector2(50, 49), Vector2(47, 59), Vector2(53, 59)])
	line([Vector2(43, 65), Vector2(55, 66)])
	if (identity >> 4) % 3 == 1:
		line([Vector2(41, 63), Vector2(49, 61), Vector2(58, 64)], INK, 2.8)
	if (identity >> 6) % 3 == 1:
		draw_arc(Vector2(41, 49), 6, 0, TAU, 16, INK, 1, true)
		draw_arc(Vector2(59, 49), 6, 0, TAU, 16, INK, 1, true)
		line([Vector2(47, 48), Vector2(53, 48)])
	if identity % 3 == 0:
		for x in range(38, 63, 3):
			line([Vector2(x, 66), Vector2(x - 2, 71)], Color("897b62"), 0.8)
	for x in range(17, 85, 5):
		line([Vector2(x, 107), Vector2(x - 3, 114)], Color("a1957b"), 0.7)
	if role in ["furnace", "ladle", "operator"]:
		draw_arc(Vector2(50, 35), 22, PI, TAU, 24, INK, 2, true)
		line([Vector2(25, 35), Vector2(75, 35)], INK, 2)
		line([Vector2(47, 14), Vector2(47, 31), Vector2(53, 31), Vector2(53, 14)])
		if role == "furnace":
			draw_rect(Rect2(33, 41, 34, 14), INK, false, 1.5)
		if role == "ladle":
			line([Vector2(31, 93), Vector2(31, 115), Vector2(70, 115), Vector2(70, 93)])
	elif role == "washer":
		draw_arc(Vector2(50, 38), 23, PI, TAU, 24, INK, 2, true)
		draw_rect(Rect2(34, 42, 32, 13), INK, false, 1.5)
		line([Vector2(39, 60), Vector2(61, 60), Vector2(57, 71), Vector2(43, 71), Vector2(39, 60)])
	elif role == "warehouse":
		line([Vector2(30, 35), Vector2(33, 22), Vector2(62, 20), Vector2(70, 33), Vector2(26, 37)], INK, 2)
		line([Vector2(63, 102), Vector2(78, 102), Vector2(77, 112), Vector2(63, 112), Vector2(63, 102)])
	else:
		draw_arc(Vector2(50, 35), 20, PI, TAU - 0.3, 20, INK, 2, true)
		for x in range(34, 65, 4):
			line([Vector2(x, 30), Vector2(x + (identity % 7) - 3, 22)], INK, 1)
		line([Vector2(69, 98), Vector2(69, 111)], INK, 2)
