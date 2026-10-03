extends HBoxContainer
## Web-style quote table and one persistent trade ticket (inputs keep focus on ticks).
const UI = preload("res://src/ui/WebLayout.gd")
var selected: String = "raw:iron"
var category: String = "raw"
var rows: Dictionary = {}
var table: VBoxContainer
var ticket_title: Label
var prices: Label
var stock: Label
var quantity: SpinBox
var minimum: SpinBox
var buy: Button
var sell: Button
var limit: Button
var ticker: Label
var orders: VBoxContainer
var last_orders: String = ""

func _label(parent: Node, text: String, font_size: int = 13) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 36
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _ready() -> void:
	add_theme_constant_override("separation", 22)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(left)
	var heading = _label(left, "Burza surovín a výrobkov", 25)
	heading.add_theme_font_override("font", preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
	var categories = HBoxContainer.new()
	left.add_child(categories)
	_button(categories, "Suroviny", func(): _category("raw"))
	_button(categories, "Výrobky", func(): _category("goods"))
	table = VBoxContainer.new()
	table.add_theme_constant_override("separation", 7)
	left.add_child(table)
	ticker = _label(left, "", 12)
	ticker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	orders = VBoxContainer.new()
	left.add_child(orders)
	var ticket = PanelContainer.new()
	ticket.custom_minimum_size.x = 295
	ticket.size_flags_vertical = SIZE_SHRINK_BEGIN
	ticket.add_theme_stylebox_override("panel", UI.panel_style("#223b46", 18))
	add_child(ticket)
	var form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 10)
	ticket.add_child(form)
	ticket_title = _label(form, "", 24)
	ticket_title.add_theme_font_override("font", preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
	ticket_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prices = _label(form, "", 14)
	stock = _label(form, "", 12)
	_label(form, "Množstvo", 12)
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = 100000
	quantity.value = 10
	form.add_child(quantity)
	var actions = HBoxContainer.new()
	form.add_child(actions)
	buy = _button(actions, "Nakúpiť", func(): _trade("buy"))
	sell = _button(actions, "Predať", func(): _trade("sell"))
	buy.size_flags_horizontal = SIZE_EXPAND_FILL
	sell.size_flags_horizontal = SIZE_EXPAND_FILL
	var note = _label(form, "Nákupy surovín prídu na rampu. Výrobky sa predávajú až po očistení.", 11)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(HSeparator.new())
	_label(form, "Minimálna cena za výrobok", 12)
	minimum = SpinBox.new()
	minimum.min_value = 1
	minimum.max_value = 100000
	minimum.value = 150
	form.add_child(minimum)
	limit = _button(form, "Zadať predajný pokyn", func():
		GameManager.execute({"type": "limit", "product": selected.trim_prefix("goods:"), "quantity": int(quantity.value), "minPrice": int(minimum.value)})
		refresh(GameManager.state)
	)
	quantity.value_changed.connect(func(_v): refresh(GameManager.state))
	_category("raw")

func _category(id: String) -> void:
	category = id
	rows.clear()
	for c in table.get_children():
		table.remove_child(c)
		c.queue_free()
	var head = HBoxContainer.new()
	table.add_child(head)
	var title = _label(head, "POLOŽKA")
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	for text in ["NÁKUP", "VÝKUP", "ZÁSOBY"]:
		var l = _label(head, text, 10)
		l.custom_minimum_size.x = 85
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var items = Constants.MATERIALS if id == "raw" else Constants.PRODUCTS
	for key in items:
		if id == "goods" and not FoundryEngine.saleable(key):
			continue
		var item: String = id + ":" + key
		var row = HBoxContainer.new()
		table.add_child(row)
		var b = _button(row, items[key].name, func():
			selected = item
			refresh(GameManager.state)
		)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.clip_text = true
		var values: Array[Label] = []
		for i in range(3):
			var l = _label(row, "")
			l.custom_minimum_size.x = 85
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			values.append(l)
		rows[item] = {"button": b, "values": values}
	selected = rows.keys()[0]
	refresh(GameManager.state)

func _trade(side: String) -> void:
	GameManager.execute({"type": "trade", "item": selected, "side": side, "quantity": int(quantity.value)})
	refresh(GameManager.state)

func refresh(s: Dictionary) -> void:
	if rows.is_empty():
		return
	for item in rows:
		var q = FoundryEngine.quote(s, item)
		var raw = item.begins_with("raw:")
		var id = item.split(":")[1]
		var available = int(s.raw[id]) if raw else FoundryEngine.available(s, id)
		var labels = rows[item].values
		labels[0].text = Format.cash(q.ask) if raw else "—"
		labels[1].text = Format.cash(q.bid)
		labels[2].text = "%d %s" % [available, "kg" if raw else "ks"]
		rows[item].button.modulate = Color("#ffa75f") if item == selected else Color.WHITE
	var id = selected.split(":")[1]
	var raw = category == "raw"
	var q = FoundryEngine.quote(s, selected)
	var available = int(s.raw[id]) if raw else FoundryEngine.available(s, id)
	ticket_title.text = Constants.MATERIALS[id].name if raw else Constants.PRODUCTS[id].name
	prices.text = "Nákup %s   /   Výkup %s" % [Format.cash(q.ask) if raw else "—", Format.cash(q.bid)]
	stock.text = "Voľné zásoby: %d %s" % [available, "kg" if raw else "ks"]
	buy.visible = raw
	buy.disabled = SimulationClock.is_paused or s.money < q.ask * quantity.value
	sell.disabled = SimulationClock.is_paused or available < quantity.value
	limit.disabled = raw or SimulationClock.is_paused or available < quantity.value
	minimum.editable = not raw
	var ev = FoundryEngine.event(s)
	ticker.text = ev.title + " · " + ev.text
	var key = str(s.limits)
	if key != last_orders:
		last_orders = key
		for child in orders.get_children():
			orders.remove_child(child)
			child.queue_free()
		for order in s.limits:
			var row = HBoxContainer.new()
			orders.add_child(row)
			_label(row, "%s · %d ks · min. %d ₵" % [Constants.PRODUCTS[order.product].name, order.quantity, order.minPrice])
			_button(row, "Zrušiť", func():
				GameManager.execute({"type": "cancelLimit", "id": order.id})
				refresh(GameManager.state)
			)
