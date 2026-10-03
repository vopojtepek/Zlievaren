extends VBoxContainer
## Persistent cards: ticks update values without replacing focused buttons.
signal command_requested(command: Dictionary)

const DISPLAY = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var cards: Dictionary = {}
var companies: Dictionary = {}
var active_label: Label
var company_grid: GridContainer
var contract_grid: GridContainer

func label(parent: Node, text: String = "", font_size: int = 12, color: String = "#a9c2c6") -> Label:
	var node = Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color(color))
	if font_size >= 24:
		node.add_theme_font_override("font", DISPLAY)
	parent.add_child(node)
	return node

func style(background: String, border: String, margin: int = 19) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color(background)
	box.border_color = Color(border)
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(margin)
	return box

func card(parent: Node, background: String, margin: int) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(background, "#3c5965", margin))
	parent.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	return box

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)
	label(self, "Buduj dôveru odberateľov.", 30, "#e9eee5")
	label(self, "Ponuku prijmi do 12 herných hodín (90 s). Od prijatia máš 18 hodín (135 s) na dodanie. Včasné splnenie: vzťah +10, reputácia +2. Zmeškanie: vzťah −15, reputácia −1. Neprijatá ponuka vyprší bez postihu.")
	active_label = label(self, "Aktívne 0 / 2", 13, "#d4e9bf")
	company_grid = GridContainer.new()
	company_grid.add_theme_constant_override("h_separation", 12)
	company_grid.add_theme_constant_override("v_separation", 12)
	add_child(company_grid)
	for buyer in Constants.COMPANIES:
		var box = card(company_grid, "#20353e", 15)
		var heading = HBoxContainer.new()
		box.add_child(heading)
		var title = label(heading, buyer, 13, "#e9eee5")
		var score = label(heading, "", 18)
		score.size_flags_horizontal = Control.SIZE_FILL
		score.autowrap_mode = TextServer.AUTOWRAP_OFF
		var relationship = label(box)
		var meter = ProgressBar.new()
		meter.min_value = -100
		meter.max_value = 100
		meter.show_percentage = false
		meter.custom_minimum_size.y = 8
		meter.add_theme_stylebox_override("background", style("#142731", "#142731", 0))
		meter.add_theme_stylebox_override("fill", style("#9bd8bd", "#9bd8bd", 0))
		box.add_child(meter)
		companies[buyer] = {"title": title, "score": score, "relationship": relationship, "meter": meter, "terms": label(box, "", 11), "history": label(box, "", 10)}
	label(self, "Vzťah −100 až +100. Pri maximálnej dôvere až 3× väčšie zákazky a +30 % ceny. Bonus sa počíta zo základných odmien znížených o 25 %. Nové ponuky prichádzajú o polnoci; vydané podmienky sa nemenia.")
	contract_grid = GridContainer.new()
	contract_grid.add_theme_constant_override("h_separation", 16)
	contract_grid.add_theme_constant_override("v_separation", 16)
	add_child(contract_grid)
	resized.connect(_resize)
	get_viewport().size_changed.connect(_resize)
	_resize()

func _resize() -> void:
	if contract_grid == null:
		return
	var width = get_viewport_rect().size.x
	contract_grid.columns = 1 if width <= 620 else (2 if width <= 850 else 3)
	company_grid.columns = maxi(1, mini(Constants.COMPANIES.size(), int((size.x + 12) / 197)))

func _create_contract(id: String) -> Dictionary:
	var box = card(contract_grid, "#203943", 19)
	var heading = HBoxContainer.new()
	box.add_child(heading)
	var buyer = label(heading, "", 10)
	var status = label(heading, "", 12, "#d4e9bf")
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var product_row = HBoxContainer.new()
	product_row.add_theme_constant_override("separation", 12)
	box.add_child(product_row)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	product_row.add_child(icon)
	var product = label(product_row, "", 24, "#e9eee5")
	var quantity = label(box, "", 28, "#d7e3de")
	var payout = label(box, "", 27, "#ffa75f")
	var unit = label(box, "", 11)
	var stock = label(box)
	var dates = label(box, "", 12, "#cbded9")
	var deadline = label(box, "", 12, "#c5d5d0")
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var button = Button.new()
	button.custom_minimum_size.y = 42
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 12)
	box.add_child(button)
	button.pressed.connect(func():
		if not button.disabled:
			command_requested.emit({"type": "contract", "id": id, "action": button.get_meta("action")})
	)
	return {"panel": box.get_parent(), "buyer": buyer, "status": status, "icon": icon, "product": product, "quantity": quantity, "payout": payout, "unit": unit, "stock": stock, "dates": dates, "deadline": deadline, "button": button}

func refresh(state: Dictionary, paused: bool) -> void:
	var active = 0
	var ids: Array = []
	for c in state.contracts:
		ids.append(c.id)
		if c.status == "active":
			active += 1
	active_label.text = "Aktívne %d / 2" % active
	for buyer in companies:
		var ui: Dictionary = companies[buyer]
		var r = FoundryEngine.relationship(state, buyer)
		var terms = FoundryEngine.company_terms(state, buyer)
		ui.score.text = ("+" if r.score > 0 else "") + str(r.score)
		ui.score.add_theme_color_override("font_color", Color("#ffb093" if r.score < 0 else "#9bd8bd"))
		ui.relationship.text = terms.label
		ui.meter.value = r.score
		ui.terms.text = "Ďalšie ponuky: %s%d %% ceny · %d %% množstva" % ["+" if terms.bonus >= 0 else "", terms.bonus, round(maxf(0.5, terms.volume) * 100)]
		ui.history.text = "%d dodaných · %d zmeškaných" % [r.delivered, r.missed]
	for id in cards.keys():
		if not ids.has(id):
			contract_grid.remove_child(cards[id].panel)
			cards[id].panel.queue_free()
			cards.erase(id)
	for i in range(state.contracts.size()):
		var c: Dictionary = state.contracts[i]
		if not cards.has(c.id):
			cards[c.id] = _create_contract(c.id)
		var ui: Dictionary = cards[c.id]
		contract_grid.move_child(ui.panel, i)
		var accepted: bool = c.status == "active"
		var offer: bool = c.status == "offer"
		var closed: bool = not accepted and not offer
		var free = FoundryEngine.available(state, c.product)
		var end: float = float(c.deadline) if accepted else float(c.offerDeadline)
		var left: float = maxf(0, end - float(state.clock))
		ui.buyer.text = c.buyer
		ui.status.text = {"offer": "Ponuka", "active": "Prijatá", "done": "Splnená", "expired": "Zmeškaná", "lapsed": "Ponuka vypršala"}[c.status]
		ui.product.text = Constants.PRODUCTS[c.product].short
		var path = "res://assets/textures/products/%s.svg" % c.product
		if ui.icon.get_meta("product", "") != c.product:
			ui.icon.texture = load(path) if ResourceLoader.exists(path) else null
			ui.icon.set_meta("product", c.product)
		ui.quantity.text = "%d kusov na dodanie" % c.quantity
		ui.payout.text = Format.cash(c.payout)
		ui.unit.text = "%s / kus · vzťah %s%d %%" % [Format.cash(round(float(c.payout) / c.quantity * 10) / 10), "+" if c.bonus > 0 else "", c.bonus]
		ui.stock.text = "Na sklade %d / %d voľných kusov." % [free, c.quantity]
		ui.dates.text = "" if closed else ("Dodať do " if accepted else "Prijať do ") + "D%d · %s" % [FoundryEngine.day({"clock": end}), Format.clock_time(end)] + ("" if accepted else "\nDodanie: 135 s od prijatia")
		ui.deadline.text = {"done": "Dodané včas · vzťah +10", "expired": "Nedodané včas · vzťah −15", "lapsed": "Neprijaté · bez postihu"}.get(c.status, "Termín uplynul" if left <= 0 else ("Na dodanie: " if accepted else "Na prijatie: ") + Format.duration(left) + " · %d s" % ceil(left))
		ui.deadline.add_theme_color_override("font_color", Color("#ffb093" if not closed and left < 30 else "#c5d5d0"))
		ui.button.text = {"done": "Zákazka dokončená", "expired": "Zákazka uzavretá", "lapsed": "Ponuka už nie je platná"}.get(c.status, "Dodať %d ks · +%s" % [c.quantity, Format.cash(c.payout)] if accepted else "Prijať zákazku")
		ui.button.disabled = paused or closed or state.clock >= end or (accepted and free < c.quantity) or (offer and active >= 2)
		ui.button.set_meta("action", "fulfill" if accepted else "accept")
		if ui.panel.get_meta("status", "") != c.status:
			ui.panel.set_meta("status", c.status)
			ui.panel.add_theme_stylebox_override("panel", style("#203943", "#a6b997" if accepted else ("#6b9672" if c.status == "done" else "#3c5965")))
			ui.panel.modulate.a = {"done": 0.8, "expired": 0.6, "lapsed": 0.65}.get(c.status, 1.0)
			ui.button.add_theme_stylebox_override("normal", style("#ffa75f" if accepted else "#203943", "#ffa75f" if accepted else "#57737b", 10))
			ui.button.add_theme_color_override("font_color", Color("#272b25" if accepted else "#e9eee5"))
