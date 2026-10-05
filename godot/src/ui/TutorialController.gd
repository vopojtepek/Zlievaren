extends CanvasLayer
## Guided real-game actions. The simulation clock is held independently of pause.
const ROLES = ["ladle", "furnace", "warehouse", "operator", "washer"]
const ROLE_NAMES = {"ladle": "panvára", "furnace": "taviča", "warehouse": "skladníka", "operator": "obsluhu odstredivky č. 1", "washer": "obsluhu pieskovača", "foreman": "majstra"}
const COPY = [
	["Vitaj v zlievarni", "Spolu vyrobíme, očistíme a predáme prvú liatinovú rúru. Všetky nákupy aj výrobky zostanú v tvojej hre."],
	["Otvor Kanceláriu", "Stroje potrebujú ľudí na aktuálnej smene. Počas čítania čas stojí."],
	["Otvor Nábor", "Majstri už pracujú. Ostatné profesie prijmeš osobitne pre každú smenu."],
	["Vyber profesiu", "Každá profesia má inú úlohu vo výrobnom reťazci."],
	["Prijmi uchádzača", "Porovnaj mzdu a absenciu. Pri obsluhe odstredivky aj riziko nepodarku. Vyber si ktoréhokoľvek uchádzača v zvýraznenej smene."],
	["Otvor Sklad", "Tu nájdeš zásobníky aj burzu surovín a výrobkov."],
	["Vyber zinok na burze", "Na rúru potrebuješ železo aj zinok. Počiatočné zásoby už stačia; malým nákupom si vyskúšaš zásobovanie."],
	["Nastav 1 kg", "Nekupuj zbytočne veľa: materiál viaže kapitál a zaberá kapacitu skladu."],
	["Nakúp zinok", "Skontroluj nákupnú cenu. Nakúpená surovina príde na rampu, odkiaľ ju treba uskladniť."],
	["Otvor zásobník zinku", "Rampa a zásobník sú dve rôzne miesta. Výroba používa materiál zo zásobníka."],
	["Uskladni nákup z rampy", "Skladník presunie dodávku do zásobníka. Až potom je dostupná na tavenie."],
	["Zavri zásobník", "Vrátime sa do výrobnej haly."],
	["Otvor Zlievareň", "Prvý stroj už vlastníš. Ďalší zatiaľ nepotrebuješ kupovať."],
	["Otvor odstredivku č. 1", "Tu vyberáš výrobok, vidíš recept a spúšťaš výrobu."],
	["Vyber liatinovú rúru", "Potvrď liatinovú rúru v zozname. Jeden kus spotrebuje 6 kg železa a 1 kg zinku."],
	["Odliať dávku", "Materiál sa spotrebuje pri spustení. Riziko nepodarku závisí od stroja aj jeho obsluhy."],
	["Prebieha odlievanie", "Sleduj plnenie, nalievanie a chladenie. Čas teraz beží. Po dokončení treba výrobok prevziať."],
	["Odnes výrobok na paletu", "Hotový kus ešte čaká v stroji. Obsluha ho musí vyložiť, aby bol dostupný na čistenie."],
	["Prebieha vyloženie", "Obsluha odnáša výrobok na paletu. Počkáme, kým bude dostupný v zásobách."],
	["Otvor Pieskovač", "Neočistený odliatok sa nedá predať. Najprv ho očistíme."],
	["Otvor ovládanie pieskovača", "Pieskovač potrebuje vlastnú obsluhu a skladníka na naloženie."],
	["Vyber liatinovú rúru", "Vyber rovnaký druh, aký si práve vyrobil."],
	["Nalož a vyčisti výrobok", "Čistenie spotrebuje mince na vodu a energiu. Očistený výrobok sa potom dá predať."],
	["Prebieha čistenie", "Po naložení sa výrobok očistí a vysunie. Očistený kus pribudne do skladu."],
	["Zavri pieskovač", "Výrobok je pripravený na predaj cez burzu."],
	["Otvor Sklad", "Predaj zadáš na burze v sklade."],
	["Na burze otvor Výrobky", "V ponuke sú len očistené výrobky. Výrobky vyrábaš vo vlastnej dielni."],
	["Vyber očistenú liatinovú rúru", "Skontroluj výkupnú cenu a počet dostupných kusov."],
	["Nastav 1 kus", "Predáme jeden očistený výrobok, ktorý si práve vyrobil."],
	["Predaj výrobok", "Skladník zabezpečí expedíciu. Výkupná cena je suma, ktorú dostaneš za kus."],
	["Prvý výrobok je predaný", "Tržba nie je zisk: odpočítaj materiál, čistenie a mzdy. Pre ďalšiu výrobu obsadzuj aj ďalšie smeny a sleduj zásoby. Teraz môžeš hrať samostatne."]
]
var main: Node
var layout: Control
var shade: Control
var card: PanelContainer
var title: Label
var body: Label
var progress: Label
var next_button: Button
var skip_button: Button
var target: Control
var hole := Rect2()
var masks: Array[ColorRect] = []
var border: Panel
var last_step := -1
var last_role := ""
var pending: Dictionary = {}
var ui_confirmed := false
var tracked: Control
var tracked_step := -1
var focus_target: Control
var scroll_target: Control
var scroll_size := Vector2.ZERO
var scroll_frames := 0

func build(root_node: Node, page_layout: Control) -> void:
	main = root_node
	layout = page_layout
	layer = 120
	shade = Control.new()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(4):
		var mask := ColorRect.new()
		mask.color = Color("#061018d9")
		mask.mouse_filter = Control.MOUSE_FILTER_STOP
		shade.add_child(mask)
		masks.append(mask)
	border = Panel.new()
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("#ffcc74")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	border.add_theme_stylebox_override("panel", style)
	shade.add_child(border)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", layout.panel_style("#183340", 16))
	shade.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	progress = Label.new()
	box.add_child(progress)
	title = Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 21)
	box.add_child(title)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	next_button = Button.new()
	next_button.custom_minimum_size.y = 44
	next_button.pressed.connect(func():
		if step() == 0: advance(1)
		elif step() == 30: finish("completed")
	)
	box.add_child(next_button)
	skip_button = Button.new()
	skip_button.text = "Preskočiť tutoriál"
	skip_button.custom_minimum_size.y = 44
	skip_button.pressed.connect(func(): finish("skipped"))
	box.add_child(skip_button)
	# OptionButton does not emit item_selected when the current item is chosen again.
	main.machine_inspector.product_select.get_popup().id_pressed.connect(func(id):
		if active() and step() == 14 and id == 0 and pending.is_empty(): main.machine_inspector._on_product_selected(0)
	)
	main.washer_inspector.product_select.get_popup().id_pressed.connect(func(id):
		if active() and step() == 21 and id == 0 and pending.is_empty(): main.washer_inspector._on_product_selected(0)
	)
	GameManager.tutorial_command_filter = allows_command
	GameManager.command_finished.connect(_command_finished)
	GameManager.game_started.connect(func(): last_step = -1)
	EventBus.tick_processed.connect(_tick)
	_process(0)

func data() -> Dictionary:
	return GameManager.state.get("tutorial", {})

func step() -> int:
	return int(data().get("step", 0))

func active() -> bool:
	return data().get("status", "") == "active"

func save() -> void:
	SaveManager.request_autosave()

func finish(status: String) -> void:
	if not active(): return
	data().status = status
	pending.clear()
	SimulationClock.tutorial_hold = false
	SimulationClock.tutorial_active = false
	shade.hide()
	layout._resize_page()
	layout.machine_modal._resize_panel()
	get_viewport().gui_release_focus()
	save()

func advance(value: int) -> void:
	data().step = value
	ui_confirmed = false
	pending.clear()
	save()

func _command_finished(command: Dictionary, result: Dictionary) -> void:
	if not active() or not result.get("ok", false): return
	# Commit the checkpoint with the successful action, even if a save happens
	# before the next frame. Restoring must never repeat a paid purchase.
	pending = command.duplicate(true)
	var transitions := {8: 9, 10: 11, 14: 15, 15: 16, 17: 18, 21: 22, 22: 23, 29: 30}
	if transitions.has(step()) and allows_command(command): advance(transitions[step()])

func find_target(id: String, node: Node = null) -> Control:
	if node == null: node = main
	if node is Control and node.get_meta("tutorial_id", "") == id and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var found := find_target(id, child)
		if found != null: return found
	return null

func market() -> Control:
	return layout.warehouse_market.get_child(0)

func role_key(role: String) -> String:
	return FoundryEngine.position_key(role, FoundryEngine.foreman_shift(GameManager.state) if role == "foreman" else FoundryEngine.shift(GameManager.state), 0 if role == "operator" else -1)

func missing_role() -> String:
	for role in ROLES + ["foreman"]:
		if FoundryEngine.duty(GameManager.state, role, 0 if role == "operator" else -1) == null:
			return role
	return ""

func prepare(value: int) -> void:
	if value == 0: main.office_view._switch_tab("overview")
	var room := "foundry"
	if value in [1, 2, 3, 4]: room = "office" if value > 1 else GameManager.current_room
	elif value in [6, 7, 8, 9, 10, 11, 26, 27, 28, 29]: room = "warehouse"
	elif value in [20, 21, 22, 23, 24]: room = "washer"
	elif value in [5, 12, 19, 25]: room = GameManager.current_room
	if GameManager.current_room != room: GameManager.change_room(room)
	if value in [10, 11]: layout.machine_modal.open_bin("zinc")
	elif value in [14, 15, 16, 17, 18]: layout.machine_modal.open_slot(0)
	elif value in [21, 22, 23, 24]: layout.machine_modal.open_washer()
	elif value in [1, 5, 12, 19, 25, 26, 27, 28, 29]: layout.machine_modal.close()
	if value in [3, 4]: main.office_view._switch_tab("hire")
	if value == 4 and FoundryEngine.assigned(GameManager.state, role_key(str(data().role))) == null:
		main.office_view.recruit_position_key = role_key(str(data().role))
		main.office_view._update_hire_tab(true)
	if value in [6, 7, 8] and market().category != "raw": market()._category("raw")
	if value in [27, 28, 29] and market().category != "goods": market()._category("goods")
	if value in [7, 8]: market().selected = "raw:zinc"
	if value in [8, 29]: market().quantity.value = 1
	if value in [28, 29]: market().selected = "goods:clean_iron_pipe"
	if value == 4 and FoundryEngine.assigned(GameManager.state, role_key(str(data().role))) != null:
		main.office_view._switch_tab("overview")
	market().refresh(GameManager.state)
	EventBus.tick_processed.emit(GameManager.state, 0.0)

func _tick(_state: Dictionary, _dt: float) -> void:
	# Freeze immediately at a finished cycle, before the next physics tick.
	if active():
		if step() == 16 and GameManager.state.machines[0].state == "ready": SimulationClock.tutorial_hold = true
		if step() == 18 and GameManager.state.goods.iron_pipe > 0: SimulationClock.tutorial_hold = true
		if step() == 23 and GameManager.state.goods.clean_iron_pipe > 0: SimulationClock.tutorial_hold = true
		if step() == 23 and FoundryEngine.duty(GameManager.state, "washer") == null: SimulationClock.tutorial_hold = true
		if step() == 16 and not GameManager.state.machines[0].served and not missing_role().is_empty(): SimulationClock.tutorial_hold = true

func _process(_delta: float) -> void:
	if shade == null: return
	shade.visible = active()
	SimulationClock.tutorial_active = active()
	if not active():
		SimulationClock.tutorial_hold = false
		return
	var s: Dictionary = GameManager.state
	var n := step()
	SimulationClock.tutorial_hold = n not in [16, 18, 23]
	if n >= 5 and n < 30 and n != 18 and not (n == 23 and FoundryEngine.duty(s, "washer") != null) and not (n == 16 and s.machines[0].served) and not missing_role().is_empty():
		data().resume = n
		advance(1)
		n = 1
	if n != last_step or str(data().get("role", "")) != last_role:
		last_step = n
		last_role = str(data().get("role", ""))
		prepare(n)
		target = null
		tracked = null
		ui_confirmed = false
	if n == 1 and GameManager.current_room == "office": advance(2)
	elif n == 2 and main.office_view.active_tab == "hire": advance(3)
	elif n == 3:
		var role := missing_role()
		if role.is_empty():
			var resume := int(data().get("resume", -1))
			data().resume = -1
			advance(resume if resume >= 5 else 5)
		else:
			data().role = role
			if ui_confirmed: advance(4)
	elif n == 4 and FoundryEngine.duty(s, str(data().role), 0 if data().role == "operator" else -1) != null: advance(3)
	elif n == 5 and GameManager.current_room == "warehouse": advance(6)
	elif n == 6 and market().selected == "raw:zinc": advance(7)
	elif n == 7 and int(market().quantity.value) == 1: advance(8)
	elif n == 8 and pending.get("type") == "trade" and pending.get("side") == "buy" and pending.get("item") == "raw:zinc" and pending.get("quantity") == 1: advance(9)
	elif n == 9 and layout.machine_modal.visible and GameManager.selected_bin == "zinc": advance(10)
	elif n == 10 and pending.get("type") == "store" and pending.get("material") == "zinc": advance(11)
	elif n == 11 and not layout.machine_modal.visible: advance(12)
	elif n == 12 and GameManager.current_room == "foundry": advance(13)
	elif n == 13 and layout.machine_modal.visible and GameManager.selected_machine == 0: advance(14)
	elif n == 14 and pending.get("type") == "machine" and pending.get("slot") == 0 and pending.get("action") == "configure" and pending.get("product") == "iron_pipe": advance(15)
	elif n == 15 and pending.get("action") == "cast" and pending.get("slot") == 0: advance(16)
	elif n == 16:
		if s.machines[0].state == "ready": advance(17)
		elif s.machines[0].state == "idle": advance(15)
	elif n == 17 and pending.get("action") == "collect": advance(18)
	elif n == 18 and s.goods.iron_pipe > 0: advance(19)
	elif n == 19 and GameManager.current_room == "washer": advance(20)
	elif n == 20 and layout.machine_modal.visible: advance(21)
	elif n == 21 and pending.get("type") == "washer" and pending.get("action") == "configure" and pending.get("product") == "iron_pipe": advance(22)
	elif n == 22 and pending.get("type") == "washer" and pending.get("action") == "start": advance(23)
	elif n == 23 and s.goods.clean_iron_pipe > 0: advance(24)
	elif n == 24 and not layout.machine_modal.visible: advance(25)
	elif n == 25 and GameManager.current_room == "warehouse": advance(26)
	elif n == 26 and market().category == "goods": advance(27)
	elif n == 27 and market().selected == "goods:clean_iron_pipe": advance(28)
	elif n == 28 and int(market().quantity.value) == 1: advance(29)
	elif n == 29 and pending.get("quantity") == 1 and pending.get("type") == "trade" and pending.get("side") == "sell" and pending.get("item") == "goods:clean_iron_pipe": advance(30)
	if step() != n: return
	if n in [9, 13, 20]: layout.device_buttons.show()
	target = resolve_target(n)
	if target != focus_target:
		focus_target = target
		var options := permitted_focus()
		if not options.is_empty(): options[0].grab_focus()
	progress.text = "SPRIEVODCA VÝROBOU · %d / %d" % [n + 1, COPY.size()]
	title.text = COPY[n][0]
	body.text = COPY[n][1]
	if n in [3, 4]:
		title.text = ("Vyber " if n == 3 else "Prijmi ") + str(ROLE_NAMES.get(data().role, data().role))
		body.text += "\nAktuálna smena: " + Constants.CREWS[FoundryEngine.shift(s)].hours
		if int(data().get("resume", -1)) >= 5: body.text += "\nSmena sa zmenila. Pred pokračovaním obsadíme novú smenu."
	if n == 4 and FoundryEngine.assigned(s, role_key(str(data().role))) != null:
		title.text = "Zavolaj zastúpenie"
		body.text = "Zamestnanec neprišiel na smenu. Vyber dostupné zastúpenie s príplatkom 50 %. Ak nie je dostupné, tutoriál môžeš preskočiť a upraviť obsadenie v Kancelárii."
	if n in [15, 16] and s.scrapped > 0:
		body.text += "\nVznikol nepodarok: vsádzka sa spotrebovala. Po odstránení spusti ďalšiu dávku."
	next_button.visible = n in [0, 30]
	next_button.text = "Začať" if n == 0 else "Hrať samostatne"
	if n == 30:
		body.text += "\nTržby z výrobkov: %s. Čistenie jedného kusu: %s." % [Format.cash(s.revenue), Format.cash(Constants.WASH.cost)]
	_track_confirmation(n)
	_position_overlay()

func resolve_target(n: int) -> Control:
	match n:
		1: return layout.nav_buttons.office
		2: return main.office_view.btn_tab_hire
		3: return find_target("role:" + str(data().role) + (":0" if data().role == "operator" else ":-1"))
		4:
			var key := role_key(str(data().role))
			return find_target(("cover:" if FoundryEngine.assigned(GameManager.state, key) != null else "candidates:") + key)
		5, 25: return layout.nav_buttons.warehouse
		6: return find_target("item:raw:zinc")
		7, 28: return market().quantity
		8: return market().buy
		9: return find_target("bin:zinc")
		10: return main.warehouse_inspector.btn_stock_move
		11, 24: return layout.machine_modal.close_button
		12: return layout.nav_buttons.foundry
		13: return find_target("machine:0")
		14: return main.machine_inspector.product_select
		15, 17: return main.machine_inspector.btn_action
		16, 18: return main.machine_inspector.cycle_bar
		19: return layout.nav_buttons.washer
		20: return find_target("washer:open")
		21: return main.washer_inspector.product_select
		22: return main.washer_inspector.btn_start
		23: return main.washer_inspector.progress_bar
		26: return find_target("market:goods")
		27: return find_target("item:goods:clean_iron_pipe")
		29: return market().sell
	return null

func _track_confirmation(n: int) -> void:
	if n != 3 or target == null or tracked == target and tracked_step == n: return
	tracked = target
	tracked_step = n
	var expected := str(data().role)
	target.pressed.connect(func():
		if active() and step() == 3 and data().role == expected: ui_confirmed = true
	, CONNECT_ONE_SHOT)

func _position_overlay() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(340, viewport_size.x - 24)
	card.custom_minimum_size.x = width
	card.size = Vector2(width, 0)
	hole = Rect2()
	if viewport_size.x < 850 and layout.machine_modal.visible:
		var modal: Control = layout.machine_modal
		modal.panel.size.y = maxf(200, viewport_size.y - card.size.y - 48)
		modal.panel.position.y = 12
	if is_instance_valid(target) and target.is_visible_in_tree():
		if scroll_target != target or scroll_size != viewport_size:
			scroll_target = target
			scroll_size = viewport_size
			scroll_frames = 20
		if scroll_frames > 0:
			scroll_frames -= 1
			var anchor: Control = target.get_child(0) if step() == 4 and target.get_child_count() > 0 else target
			var parent := anchor.get_parent()
			while parent != null:
				if parent is ScrollContainer:
					var area: Rect2 = parent.get_global_rect()
					if parent == layout.scroll and viewport_size.x < 850:
						area.size.y = maxf(1, viewport_size.y - card.size.y - 40)
					var rect := anchor.get_global_rect()
					var delta := 0.0
					if rect.size.y > area.size.y or rect.position.y < area.position.y + 12:
						delta = rect.position.y - area.position.y - 12
					elif rect.end.y > area.end.y - 12:
						delta = rect.end.y - area.end.y + 12
					if absf(delta) > 1:
						var before: int = parent.scroll_vertical
						parent.scroll_vertical += int(ceil(delta))
						if before != parent.scroll_vertical: break
				parent = parent.get_parent()
		var rect := target.get_global_rect()
		var parent := target.get_parent()
		while parent != null:
			if parent is ScrollContainer: rect = rect.intersection(parent.get_global_rect())
			parent = parent.get_parent()
		if viewport_size.x < 850:
			rect = rect.intersection(Rect2(0, 0, viewport_size.x, maxf(1, viewport_size.y - card.size.y - 40)))
		hole = rect.grow(5).intersection(Rect2(Vector2.ZERO, viewport_size)) if rect.has_area() else Rect2()
	border.visible = hole.has_area()
	border.position = hole.position
	border.size = hole.size
	var x := (viewport_size.x - width) / 2
	var y := (viewport_size.y - card.size.y) / 2
	if hole.has_area():
		if hole.end.x + width + 24 <= viewport_size.x:
			x = hole.end.x + 12
			y = clampf(hole.position.y, 12, maxf(12, viewport_size.y - card.size.y - 12))
		elif hole.position.x >= width + 24:
			x = hole.position.x - width - 12
			y = clampf(hole.position.y, 12, maxf(12, viewport_size.y - card.size.y - 12))
		elif hole.end.y + card.size.y + 24 <= viewport_size.y:
			y = hole.end.y + 12
		elif hole.position.y >= card.size.y + 24:
			y = hole.position.y - card.size.y - 12
		else:
			# Reserve the bottom for the card and scroll the real target above it.
			y = maxf(12, viewport_size.y - card.size.y - 12)
	card.position = Vector2(x, y)
	var rectangles: Array[Rect2] = [
		Rect2(0, 0, viewport_size.x, hole.position.y),
		Rect2(0, hole.end.y, viewport_size.x, maxf(0, viewport_size.y - hole.end.y)),
		Rect2(0, hole.position.y, hole.position.x, hole.size.y),
		Rect2(hole.end.x, hole.position.y, maxf(0, viewport_size.x - hole.end.x), hole.size.y)
	]
	if not hole.has_area(): rectangles = [Rect2(Vector2.ZERO, viewport_size), Rect2(), Rect2(), Rect2()]
	for i in range(4):
		masks[i].position = rectangles[i].position
		masks[i].size = rectangles[i].size

func _input(event: InputEvent) -> void:
	if not active(): return
	if event is InputEventKey:
		var focus := get_viewport().gui_get_focus_owner()
		var allowed := focus != null and (card.is_ancestor_of(focus) or focus == target or is_instance_valid(target) and target.is_ancestor_of(focus))
		if event.keycode == KEY_TAB:
			if event.pressed:
				var options := permitted_focus()
				if not options.is_empty():
					var index := options.find(focus)
					index = posmod(index + (-1 if event.shift_pressed else 1), options.size())
					options[index].grab_focus()
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_P, KEY_ESCAPE] or not allowed:
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		var point: Vector2 = event.position
		if not card.get_global_rect().has_point(point) and not hole.has_point(point):
			if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and is_instance_valid(target):
				var parent := target.get_parent()
				while parent != null:
					if parent is ScrollContainer:
						parent.scroll_vertical += -70 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 70
						break
					parent = parent.get_parent()
			get_viewport().set_input_as_handled()

func allows_command(command: Dictionary) -> bool:
	if not active(): return true
	match step():
		4:
			return command.get("type") == "personnel" and command.get("action") in ["hire", "overtime"] and command.get("position") == role_key(str(data().role))
		8:
			return command.get("type") == "trade" and command.get("side") == "buy" and command.get("item") == "raw:zinc" and command.get("quantity") == 1
		10:
			return command.get("type") == "store" and command.get("material") == "zinc"
		14:
			return command.get("type") == "machine" and command.get("slot") == 0 and command.get("action") == "configure" and command.get("product") == "iron_pipe"
		15:
			return command.get("type") == "machine" and command.get("slot") == 0 and command.get("action") == "cast"
		17:
			return command.get("type") == "machine" and command.get("slot") == 0 and command.get("action") == "collect"
		21:
			return command.get("type") == "washer" and command.get("action") == "configure" and command.get("product") == "iron_pipe"
		22:
			return command.get("type") == "washer" and command.get("action") == "start"
		29:
			return command.get("type") == "trade" and command.get("side") == "sell" and command.get("item") == "goods:clean_iron_pipe" and command.get("quantity") == 1
	return false

func _exit_tree() -> void:
	SimulationClock.tutorial_active = false
	SimulationClock.tutorial_hold = false
	GameManager.tutorial_command_filter = Callable()

func permitted_focus() -> Array[Control]:
	var controls: Array[Control] = []
	if is_instance_valid(target): gather_focus(target, controls)
	if next_button.visible: controls.append(next_button)
	controls.append(skip_button)
	return controls

func gather_focus(node: Node, controls: Array[Control]) -> void:
	if node is Control and node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL:
		if not node is BaseButton or not node.disabled: controls.append(node)
	for child in node.get_children(): gather_focus(child, controls)
