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

@onready var contracts_list: VBoxContainer = $VBox/Content/ContractsPanel/Scroll/ContractsList
@onready var companies_list: HBoxContainer = $VBox/Content/ContractsPanel/CompaniesList

@onready var ledger_list: VBoxContainer = $VBox/Content/LedgerPanel/Scroll/LedgerList

var current_tab: String = "market"
var current_state: Dictionary = {}
var _last_market_key: String = ""
var _last_contracts_key: String = ""
var _last_ledger_key: String = ""

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
	_connect_signals()
	visibility_changed.connect(_on_visibility_changed)
	
	btn_market.pressed.connect(func(): _switch_tab("market"))
	btn_contracts.pressed.connect(func(): _switch_tab("contracts"))
	btn_ledger.pressed.connect(func(): _switch_tab("ledger"))
	
	_switch_tab("market")
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
		_update_market(state, force)
	elif current_tab == "contracts":
		_update_contracts(state, force)
	elif current_tab == "ledger":
		_update_ledger(state, force)

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

func _update_contracts(state: Dictionary, force: bool = false) -> void:
	var paused = SimulationClock.is_paused
	var contracts_key = "%d:%d:%s" % [
		state.get("revision", 0),
		int(ceil(state.clock)),
		str(paused)
	]
	if not force and contracts_key == _last_contracts_key:
		return
	_last_contracts_key = contracts_key
	
	for child in contracts_list.get_children():
		child.queue_free()
		
	var contracts = state.contracts
	var active_or_offers = []
	for c in contracts:
		if c.status == "offer" or c.status == "active":
			active_or_offers.append(c)
			
	if active_or_offers.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Momentálne nie sú dostupné žiadne zákazky. Nové ponuky prichádzajú každých 90 sekúnd."
		contracts_list.add_child(empty_lbl)
	else:
		for c in active_or_offers:
			var card = PanelContainer.new()
			card.mouse_filter = Control.MOUSE_FILTER_PASS
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.14, 0.20, 0.22, 0.95)
			style.border_color = Color(0.3, 0.45, 0.5, 1.0)
			style.set_border_width_all(1)
			style.set_corner_radius_all(6)
			card.add_theme_stylebox_override("panel", style)
			
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 16)
			
			var contract_icon = TextureRect.new()
			contract_icon.custom_minimum_size = Vector2(36, 36)
			contract_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			contract_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var c_icon_path = "res://assets/textures/products/%s.svg" % c.product
			if ResourceLoader.exists(c_icon_path):
				contract_icon.texture = load(c_icon_path)
			hbox.add_child(contract_icon)
			
			var vbox = VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var buyer_lbl = Label.new()
			buyer_lbl.text = "%s · %s" % [c.buyer, "PONUKA" if c.status == "offer" else "AKTÍVNA ZÁKAZKA"]
			buyer_lbl.modulate = Color(0.957, 0.808, 0.533, 1)
			vbox.add_child(buyer_lbl)
			
			var p = Constants.PRODUCTS.get(c.product, {})
			var prod_name = p.get("name", c.product)
			var avail = FoundryEngine.available(state, c.product)
			var desc_lbl = Label.new()
			desc_lbl.text = "Požiadavka: %d ks %s (na sklade máš %d ks)" % [c.quantity, prod_name, avail]
			vbox.add_child(desc_lbl)
			
			var time_left = maxf(0.0, c.deadline - state.clock)
			var time_lbl = Label.new()
			if c.status == "offer":
				time_lbl.text = "Platnosť ponuky: %d s · Odmena: %s" % [int(ceil(time_left)), Format.cash(c.payout)]
			else:
				time_lbl.text = "Termín dodania: %d s · Odmena: %s" % [int(ceil(time_left)), Format.cash(c.payout)]
			time_lbl.modulate = Color(0.4, 0.9, 0.6) if time_left > 30 else Color(1.0, 0.4, 0.4)
			vbox.add_child(time_lbl)
			
			hbox.add_child(vbox)
			
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(140, 40)
			var cid = c.id
			if c.status == "offer":
				btn.text = "Prijať zákazku"
				btn.disabled = paused
				btn.pressed.connect(func():
					_execute({ "type": "contract", "action": "accept", "id": cid })
					_update_view(true)
				)
			else:
				btn.text = "Splniť zákazku"
				btn.disabled = paused or avail < c.quantity
				btn.pressed.connect(func():
					_execute({ "type": "contract", "action": "fulfill", "id": cid })
					_update_view(true)
				)
			hbox.add_child(btn)
			
			card.add_child(hbox)
			contracts_list.add_child(card)
			
	# Company relationships
	for child in companies_list.get_children():
		child.queue_free()
		
	for comp_name in Constants.COMPANIES:
		var rel = FoundryEngine.relationship(state, comp_name)
		var rel_lbl = Label.new()
		rel_lbl.text = "%s: %d %% dôvera (%d dodaných)" % [comp_name, rel.score, rel.delivered]
		rel_lbl.add_theme_font_size_override("font_size", 11)
		rel_lbl.modulate = Color(0.7, 0.85, 0.8)
		companies_list.add_child(rel_lbl)

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
