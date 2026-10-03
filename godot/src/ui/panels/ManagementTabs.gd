class_name ManagementTabs
extends PanelContainer

@onready var btn_market: Button = $VBox/Header/Tabs/BtnMarket
@onready var btn_contracts: Button = $VBox/Header/Tabs/BtnContracts
@onready var btn_ledger: Button = $VBox/Header/Tabs/BtnLedger

@onready var market_panel: VBoxContainer = $VBox/Content/MarketPanel
@onready var contracts_panel: VBoxContainer = $VBox/Content/ContractsPanel
@onready var ledger_panel: VBoxContainer = $VBox/Content/LedgerPanel

@onready var market_ticker: Label = $VBox/Content/MarketPanel/TickerLabel
@onready var market_items_list: VBoxContainer = $VBox/Content/MarketPanel/Scroll/ItemsList

var web_contracts: VBoxContainer

@onready var ledger_list: VBoxContainer = $VBox/Content/LedgerPanel/Scroll/LedgerList

var current_tab: String = "market"
var current_state: Dictionary = {}
var _last_market_key: String = ""
var _last_ledger_key: String = ""
var extra_buttons: Dictionary = {}
var stock_panel: HBoxContainer
var development_panel: HBoxContainer
var _last_extra_key: String = ""
var web_market: HBoxContainer

func _get_state() -> Dictionary:
	if not current_state.is_empty():
		return current_state
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and gm.get("state") != null:
		return gm.state
	return {}

func _execute(cmd: Dictionary) -> Dictionary:
	if not current_state.is_empty():
		return FoundryEngine.perform(current_state, cmd)
	var gm = get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("execute"):
		return gm.execute(cmd)
	return {}

func _is_paused() -> bool:
	var clock = get_node_or_null("/root/SimulationClock")
	if clock != null:
		return clock.is_paused
	return false

func _connect_signals() -> void:
	var eb = get_node_or_null("/root/EventBus")
	if eb != null:
		if eb.has_signal("tick_processed") and not eb.tick_processed.is_connected(_on_tick):
			eb.tick_processed.connect(_on_tick)
		if eb.has_signal("pause_toggled") and not eb.pause_toggled.is_connected(_on_pause_toggled):
			eb.pause_toggled.connect(_on_pause_toggled)

func _ready() -> void:
	for child in contracts_panel.get_children():
		contracts_panel.remove_child(child)
		child.queue_free()
	web_contracts = preload("res://src/ui/panels/WebContracts.gd").new()
	contracts_panel.add_child(web_contracts)
	web_contracts.command_requested.connect(func(command: Dictionary):
		_execute(command)
		_update_view(true)
	)
	for c in market_panel.get_children():
		c.hide()
	web_market = preload("res://src/ui/panels/WebMarket.gd").new()
	market_panel.add_child(web_market)
	custom_minimum_size = Vector2(0, 430)
	add_theme_stylebox_override("panel", preload("res://src/ui/WebLayout.gd").panel_style("#162831", 22))
	stock_panel = HBoxContainer.new()
	stock_panel.add_theme_constant_override("separation", 24)
	$VBox/Content.add_child(stock_panel)
	development_panel = HBoxContainer.new()
	development_panel.add_theme_constant_override("separation", 16)
	$VBox/Content.add_child(development_panel)
	for entry in [["stock", "Sklady"], ["development", "Rozvoj"], ["office", "Kancelária"]]:
		var id: String = entry[0]
		var b = Button.new()
		b.text = entry[1]
		b.toggle_mode = true
		$VBox/Header/Tabs.add_child(b)
		b.pressed.connect(func():
			if id == "office":
				GameManager.change_room("office")
			else:
				_switch_tab(id)
		)
		extra_buttons[id] = b
	$VBox/Header/Tabs.move_child(extra_buttons.stock, 0)
	$VBox/Header/Tabs.move_child(btn_ledger, $VBox/Header/Tabs.get_child_count() - 1)
	btn_market.text = "Burza"
	for b in $VBox/Header/Tabs.get_children():
		b.custom_minimum_size.y = 52
		var normal = StyleBoxFlat.new()
		normal.bg_color = Color("#1b2f38")
		normal.set_content_margin_all(10)
		var selected = normal.duplicate()
		selected.border_width_bottom = 2
		selected.border_color = Color("#ffa75f")
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("pressed", selected)
		b.add_theme_color_override("font_pressed_color", Color("#fff0df"))
	_connect_signals()
	visibility_changed.connect(_on_visibility_changed)
	
	btn_market.pressed.connect(func(): _switch_tab("market"))
	btn_contracts.pressed.connect(func(): _switch_tab("contracts"))
	btn_ledger.pressed.connect(func(): _switch_tab("ledger"))
	
	_switch_tab("stock")
	_update_view(true)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_connect_signals()
		_update_view(true)

func _on_pause_toggled(_paused: bool) -> void:
	if is_visible_in_tree():
		_update_view(true)

func _switch_tab(tab_name: String) -> void:
	current_tab = tab_name
	btn_market.button_pressed = (current_tab == "market")
	btn_contracts.button_pressed = (current_tab == "contracts")
	btn_ledger.button_pressed = (current_tab == "ledger")
	
	market_panel.visible = (current_tab == "market")
	contracts_panel.visible = (current_tab == "contracts")
	ledger_panel.visible = (current_tab == "ledger")
	stock_panel.visible = current_tab == "stock"
	development_panel.visible = current_tab == "development"
	for id in extra_buttons:
		extra_buttons[id].set_pressed_no_signal(id == current_tab)
	_update_view(true)

func _on_tick(_state: Dictionary, _delta: float) -> void:
	if not is_visible_in_tree():
		return
	_update_view(false)

func _update_view(force: bool = false) -> void:
	var state = _get_state()
	if state == null or state.is_empty():
		return
		
	if current_tab == "market":
		web_market.refresh(state)
	elif current_tab == "contracts":
		_update_contracts(state, force)
	elif current_tab == "ledger":
		_update_ledger(state, force)
	elif current_tab in ["stock", "development"]:
		_update_extra(state, force)

func _extra_label(parent: Node, text: String, font_size: int = 13) -> Label:
	var l = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l

func _extra_card(parent: Node, title: String) -> VBoxContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", preload("res://src/ui/WebLayout.gd").panel_style("#1b303a", 17))
	parent.add_child(card)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	var heading = _extra_label(box, title, 25)
	heading.add_theme_font_override("font", preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
	return box

func _extra_action(parent: Node, title: String, command: Dictionary, disabled: bool = false) -> void:
	var b = Button.new()
	b.text = title
	b.disabled = _is_paused() or disabled
	b.pressed.connect(func():
		_execute(command)
		_update_view(true)
	)
	parent.add_child(b)

func _update_extra(s: Dictionary, force: bool) -> void:
	var key = "%s:%d:%s:%s:%s" % [current_tab, s.revision, s.raw.hash(), s.goods.hash(), _is_paused()]
	if key == _last_extra_key and not force:
		return
	_last_extra_key = key
	var panel = stock_panel if current_tab == "stock" else development_panel
	for c in panel.get_children():
		panel.remove_child(c)
		c.queue_free()
	if current_tab == "stock":
		var raw = _extra_card(panel, "Suroviny na vsádzku")
		_extra_label(raw, "%d / %d kg · dodávky na rampe %d kg" % [FoundryEngine.used(s, "raw"), FoundryEngine.capacity(s, "raw"), FoundryEngine.used(s, "incoming")])
		for id in Constants.MATERIALS:
			_extra_label(raw, "%s       %d / %d kg" % [Constants.MATERIALS[id].name, s.raw[id], FoundryEngine.bin_capacity(s, id)])
			if s.incoming[id] > 0:
				_extra_action(raw, "Uskladniť %d kg →" % s.incoming[id], {"type": "store", "material": id, "quantity": s.incoming[id]})
		var goods = _extra_card(panel, "Odliatky a očistené výrobky")
		_extra_label(goods, "%d / %d ks" % [FoundryEngine.used(s, "goods"), FoundryEngine.capacity(s, "goods")])
		for id in Constants.BASE_PRODUCTS:
			var clean: String = Constants.WASH.outputs[id]
			_extra_label(goods, "%s\n%d odliatkov · %d očistených" % [Constants.BASE_PRODUCTS[id].name, s.goods[id], s.goods[clean]])
		_extra_action(goods, "Zväčšiť sklad výrobkov", {"type": "expand", "kind": "goods"})
	else:
		for id in Constants.BASE_PRODUCTS:
			var p = Constants.BASE_PRODUCTS[id]
			var card = _extra_card(panel, p.name)
			_extra_label(card, p.description)
			_extra_label(card, "%s\nCyklus %d s" % [p.size, p.seconds])
			var unlocked = s.unlocked.has(id)
			_extra_action(card, "Odomknuté" if unlocked else "Odomknúť · %d ₵" % p.unlock, {"type": "unlock", "product": id}, unlocked or s.money < p.unlock)
		var upgrades = _extra_card(panel, "Rozvoj závodu")
		_extra_label(upgrades, "Rýchlejší záves skracuje prepravu panvy. Väčšie sklady dávajú priestor ďalšej výrobe.")
		_extra_action(upgrades, "Záves · %d ₵" % (420 * (s.logistics + 1)), {"type": "logistics"}, s.logistics >= 2)
		_extra_action(upgrades, "Zväčšiť rampu", {"type": "expand", "kind": "raw"})
		_extra_action(upgrades, "Zväčšiť sklad", {"type": "expand", "kind": "goods"})

func _update_market(state: Dictionary, force: bool = false) -> void:
	var ev = FoundryEngine.event(state)
	market_ticker.text = "%s · %s" % [ev.title, ev.text]
	
	var paused = _is_paused()
	var market_key = "%d:%d:%d:%d:%s" % [
		state.get("revision", 0), int(state.money),
		state.raw.values().hash(), state.goods.values().hash(),
		str(paused)
	]
	if not force and market_key == _last_market_key:
		return
	_last_market_key = market_key
	
	for child in market_items_list.get_children():
		child.queue_free()
		
	# Raw Materials
	var cat_raw = Label.new()
	cat_raw.text = "Suroviny na vsádzku (kg)"
	cat_raw.add_theme_color_override("font_color", Color(0.957, 0.808, 0.533, 1))
	cat_raw.add_theme_font_size_override("font_size", 14)
	market_items_list.add_child(cat_raw)
	
	for mat_id in Constants.MATERIALS.keys():
		var mat = Constants.MATERIALS[mat_id]
		var item_key = "raw:" + mat_id
		var quote = FoundryEngine.quote(state, item_key)
		if quote == null:
			continue
		var stock = state.raw.get(mat_id, 0)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(24, 24)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var mat_icon = "res://assets/textures/materials/%s.svg" % mat_id
		if ResourceLoader.exists(mat_icon):
			icon_rect.texture = load(mat_icon)
		row.add_child(icon_rect)
		
		var lbl_name = Label.new()
		lbl_name.text = mat.name
		lbl_name.custom_minimum_size = Vector2(140, 0)
		row.add_child(lbl_name)
		
		var lbl_stock = Label.new()
		lbl_stock.text = "Sklad: %d kg" % stock
		lbl_stock.custom_minimum_size = Vector2(100, 0)
		lbl_stock.modulate = Color(0.8, 0.8, 0.8)
		row.add_child(lbl_stock)
		
		var lbl_quotes = Label.new()
		lbl_quotes.text = "Nákup: %s | Predaj: %s" % [Format.cash(quote.ask), Format.cash(quote.bid)]
		lbl_quotes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_quotes)
		
		var btn_buy10 = Button.new()
		btn_buy10.text = "Kúpiť 10 kg (%s)" % Format.cash(quote.ask * 10)
		btn_buy10.disabled = _is_paused() or state.money < (quote.ask * 10)
		var ik = item_key
		btn_buy10.pressed.connect(func():
			_execute({ "type": "trade", "item": ik, "side": "buy", "quantity": 10 })
			_update_view(true)
		)
		row.add_child(btn_buy10)
		
		var btn_sell10 = Button.new()
		btn_sell10.text = "Predať 10 kg"
		btn_sell10.disabled = _is_paused() or stock < 10
		btn_sell10.pressed.connect(func():
			_execute({ "type": "trade", "item": ik, "side": "sell", "quantity": 10 })
			_update_view(true)
		)
		row.add_child(btn_sell10)
		
		market_items_list.add_child(row)
		
	# Separator
	market_items_list.add_child(HSeparator.new())
	
	# Salable Finished Goods
	var cat_goods = Label.new()
	cat_goods.text = "Hotové výrobky na predaj (ks)"
	cat_goods.add_theme_color_override("font_color", Color(0.957, 0.808, 0.533, 1))
	cat_goods.add_theme_font_size_override("font_size", 14)
	market_items_list.add_child(cat_goods)
	
	for prod_id in Constants.PRODUCTS.keys():
		var p = Constants.PRODUCTS[prod_id]
		if not FoundryEngine.saleable(prod_id):
			continue
		var quote = FoundryEngine.quote(state, "goods:" + prod_id)
		var stock = FoundryEngine.available(state, prod_id)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(24, 24)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var prod_icon = "res://assets/textures/products/%s.svg" % prod_id
		if ResourceLoader.exists(prod_icon):
			icon_rect.texture = load(prod_icon)
		row.add_child(icon_rect)
		
		var lbl_name = Label.new()
		lbl_name.text = p.name
		lbl_name.custom_minimum_size = Vector2(140, 0)
		row.add_child(lbl_name)
		
		var lbl_stock = Label.new()
		lbl_stock.text = "Voľné: %d ks" % stock
		lbl_stock.custom_minimum_size = Vector2(100, 0)
		lbl_stock.modulate = Color(0.8, 0.8, 0.8)
		row.add_child(lbl_stock)
		
		var lbl_quotes = Label.new()
		lbl_quotes.text = "Výkupná cena: %s" % Format.cash(quote.bid)
		lbl_quotes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_quotes)
		
		var btn_sell1 = Button.new()
		btn_sell1.text = "Predať 1 ks"
		btn_sell1.disabled = _is_paused() or stock < 1
		var pid = prod_id
		btn_sell1.pressed.connect(func():
			_execute({ "type": "trade", "item": "goods:" + pid, "side": "sell", "quantity": 1 })
			_update_view(true)
		)
		row.add_child(btn_sell1)
		
		var btn_sell_all = Button.new()
		btn_sell_all.text = "Predať všetko (%d ks)" % stock
		btn_sell_all.disabled = _is_paused() or stock < 1
		btn_sell_all.pressed.connect(func():
			_execute({ "type": "trade", "item": "goods:" + pid, "side": "sell", "quantity": stock })
			_update_view(true)
		)
		row.add_child(btn_sell_all)
		
		market_items_list.add_child(row)

func _update_contracts(state: Dictionary, _force: bool = false) -> void:
	web_contracts.refresh(state, _is_paused())

func _update_ledger(state: Dictionary, force: bool = false) -> void:
	var ledger_key = "%d:%d" % [state.get("revision", 0), state.ledger.size()]
	if not force and ledger_key == _last_ledger_key:
		return
	_last_ledger_key = ledger_key
	
	for child in ledger_list.get_children():
		child.queue_free()
		
	var entries = state.ledger
	if entries.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Denník je zatiaľ prázdny."
		ledger_list.add_child(empty_lbl)
	else:
		# Show latest first
		var n = entries.size()
		var start_idx = maxi(0, n - 40)
		for i in range(n - 1, start_idx - 1, -1):
			var entry = entries[i]
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			
			var badge = Label.new()
			badge.text = "[%s]" % entry.get("category", "info").to_upper()
			badge.custom_minimum_size = Vector2(80, 0)
			var cat = entry.get("category", "")
			if cat == "contract":
				badge.modulate = Color(0.957, 0.808, 0.533, 1)
			elif cat == "crew" or cat == "payroll":
				badge.modulate = Color(0.4, 0.9, 0.6)
			elif cat == "stock":
				badge.modulate = Color(0.5, 0.8, 1.0)
			else:
				badge.modulate = Color(0.7, 0.7, 0.7)
			row.add_child(badge)
			
			var text_lbl = Label.new()
			text_lbl.text = entry.get("text", "")
			text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(text_lbl)
			
			ledger_list.add_child(row)
