class_name OfficeView
extends PanelContainer
var display_mode: Node:
	get:
		return get_node('/root/DisplayMode')

const PersonnelCard = preload("res://src/ui/office/PersonnelCard.gd")

@onready var employees_count_badge: Label = $VBox/TopHeader/EmployeesCountBadge
@onready var next_pay_label: Label = $VBox/StatsStrip/NextPayBox/Value
@onready var accrued_pay_label: Label = $VBox/StatsStrip/AccruedBox/Value
@onready var weekly_pay_label: Label = $VBox/StatsStrip/WeeklyBox/Value
@onready var debt_label: Label = $VBox/StatsStrip/DebtBox/Value

@onready var debt_alert: PanelContainer = $VBox/DebtAlert
@onready var debt_alert_label: Label = $VBox/DebtAlert/HBox/Label
@onready var btn_pay_debt: Button = $VBox/DebtAlert/HBox/BtnPayDebt

@onready var btn_tab_overview: Button = $VBox/TabsNav/BtnOverview
@onready var btn_tab_hire: Button = $VBox/TabsNav/BtnHire
@onready var btn_tab_payroll: Button = $VBox/TabsNav/BtnPayroll

@onready var tab_overview_container: VBoxContainer = $VBox/ScrollContent/ContentBox/TabOverview
@onready var tab_hire_container: VBoxContainer = $VBox/ScrollContent/ContentBox/TabHire
@onready var tab_payroll_container: VBoxContainer = $VBox/ScrollContent/ContentBox/TabPayroll

@onready var shift_title_label: Label = $VBox/ScrollContent/ContentBox/TabOverview/ShiftTitle
@onready var missing_workers_list: VBoxContainer = $VBox/ScrollContent/ContentBox/TabOverview/MissingList
@onready var employees_list: GridContainer = $VBox/ScrollContent/ContentBox/TabOverview/EmployeesGrid
@onready var employee_position_buttons: GridContainer = $VBox/ScrollContent/ContentBox/TabOverview/EmployeePositionScroll/PositionButtons
@onready var employee_empty_label: Label = $VBox/ScrollContent/ContentBox/TabOverview/EmployeeEmptyLabel

@onready var recruit_position_buttons: GridContainer = $VBox/ScrollContent/ContentBox/TabHire/RecruitHead/PositionScroll/PositionButtons
@onready var recruit_formula_label: Label = $VBox/ScrollContent/ContentBox/TabHire/RecruitHead/FormulaLabel
@onready var recruit_shifts_list: VBoxContainer = $VBox/ScrollContent/ContentBox/TabHire/ShiftsList

@onready var payroll_lines_table: VBoxContainer = $VBox/ScrollContent/ContentBox/TabPayroll/LinesTable
@onready var payroll_history_list: VBoxContainer = $VBox/ScrollContent/ContentBox/TabPayroll/HistoryList

var active_tab: String = "overview"
var recruit_position_key: String = "ladle:-1:0"
var employee_position_key: String = "ladle:-1:0"
var cached_position_keys: Array = []
var current_state: Dictionary = {}
var _last_overview_key: String = ""
var _last_hire_key: String = ""
var _last_payroll_key: String = ""

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
	$VBox/ScrollContent.resized.connect(_resize_personnel_grids)
	recruit_position_buttons.set_meta("responsive_columns", true)
	employee_position_buttons.set_meta("responsive_columns", true)
	display_mode.mode_changed.connect(func(_mobile): _resize_personnel_grids())
	employees_list.add_to_group("personnel_grids")
	employees_list.set_meta("responsive_columns", true)
	_connect_signals()
	visibility_changed.connect(_on_visibility_changed)
	
	btn_tab_overview.pressed.connect(func(): _switch_tab("overview"))
	btn_tab_hire.pressed.connect(func(): _switch_tab("hire"))
	btn_tab_payroll.pressed.connect(func(): _switch_tab("payroll"))
	
	btn_pay_debt.pressed.connect(_on_pay_debt)
	
	_switch_tab("overview")
	_populate_recruit_positions()
	_update_view(true)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_connect_signals()
		_populate_recruit_positions()
		_update_view(true)

func _on_pause_toggled(_paused: bool) -> void:
	if is_visible_in_tree():
		_update_view(true)

func _switch_tab(tab_name: String) -> void:
	active_tab = tab_name
	btn_tab_overview.button_pressed = (active_tab == "overview")
	btn_tab_hire.button_pressed = (active_tab == "hire")
	btn_tab_payroll.button_pressed = (active_tab == "payroll")
	
	tab_overview_container.visible = (active_tab == "overview")
	tab_hire_container.visible = (active_tab == "hire")
	tab_payroll_container.visible = (active_tab == "payroll")
	
	if active_tab == "hire":
		_populate_recruit_positions()
	_update_view(true)

func _on_pay_debt() -> void:
	_execute({ "type": "payWages" })
	_update_view(true)

func _on_recruit_position_selected(index: int) -> void:
	if index >= 0 and index < cached_position_keys.size():
		recruit_position_key = cached_position_keys[index]
		_update_hire_tab(true)

func _populate_recruit_positions() -> void:
	var state = _get_state()
	if state == null or state.is_empty():
		return
	var positions = FoundryEngine.positions(state)
	cached_position_keys.clear()
	for child in recruit_position_buttons.get_children():
		recruit_position_buttons.remove_child(child)
		child.queue_free()
	
	for p in positions:
		if p.crew == 0:
			cached_position_keys.append(p.key)
			var button = Button.new()
			button.text = p.label
			button.tooltip_text = "Nábor · " + p.label
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(116, 100)
			button.set_meta("mobile_button_width", 116)
			_style_position_icon(button, p.role)
			button.pressed.connect(_on_recruit_position_selected.bind(cached_position_keys.size() - 1))
			recruit_position_buttons.add_child(button)
			
	if not cached_position_keys.is_empty():
		var found_match = false
		for k in cached_position_keys:
			var parts_k = k.split(":")
			var parts_cur = recruit_position_key.split(":")
			if parts_k.size() >= 2 and parts_cur.size() >= 2:
				if parts_k[0] == parts_cur[0] and parts_k[1] == parts_cur[1]:
					found_match = true
					break
		if not found_match:
			recruit_position_key = cached_position_keys[0]
	_sync_position_selection()
	_populate_employee_positions(positions)

func _populate_employee_positions(positions: Array) -> void:
	for child in employee_position_buttons.get_children():
		employee_position_buttons.remove_child(child)
		child.queue_free()
	for p in positions:
		if p.crew != 0:
			continue
		var button = Button.new()
		button.text = p.label
		button.tooltip_text = "Zamestnanci · " + p.label
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(116, 100)
		button.set_meta("mobile_button_width", 116)
		button.set_meta("employee_position", p.key)
		_style_position_icon(button, p.role)
		var position_key: String = p.key
		button.pressed.connect(func():
			employee_position_key = position_key
			_update_view(true)
		)
		employee_position_buttons.add_child(button)
	_sync_employee_position_selection()
	_resize_personnel_grids()

func _sync_employee_position_selection() -> void:
	for button in employee_position_buttons.get_children():
		var selected: bool = button.get_meta("employee_position") == employee_position_key
		button.set_pressed_no_signal(selected)
		button.modulate = Color("f4ce88") if selected else Color.WHITE

func _style_position_icon(button: Button, role: String) -> void:
	var icons = {"ladle": "worker_operator", "furnace": "worker_furnace", "warehouse": "worker_storekeeper", "washer": "worker_washer", "foreman": "foreman_miso", "operator": "worker_operator"}
	button.icon = load("res://assets/textures/characters/%s.svg" % icons[role])
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_constant_override("icon_max_width", 42)
	button.add_theme_font_size_override("font_size", 13)

func _sync_position_selection() -> void:
	var state = _get_state()
	if state == null or state.is_empty():
		return
	var positions = FoundryEngine.positions(state)
	var cur_pos = null
	for p in positions:
		if p.key == recruit_position_key:
			cur_pos = p
			break
	if cur_pos == null and not positions.is_empty():
		cur_pos = positions[0]
		recruit_position_key = cur_pos.key
	
	if cur_pos != null:
		for i in range(cached_position_keys.size()):
			var k = cached_position_keys[i]
			var button = recruit_position_buttons.get_child(i) as Button
			button.set_pressed_no_signal(false)
			button.modulate = Color.WHITE
			for p in positions:
				if p.key == k and p.role == cur_pos.role and p.slot == cur_pos.slot:
					button.set_pressed_no_signal(true)
					button.modulate = Color("f4ce88")

func _on_tick(_state: Dictionary, _delta: float) -> void:
	if not is_visible_in_tree():
		return
	_update_view(false)

func _update_view(force: bool = false) -> void:
	var state = _get_state()
	if state == null or state.is_empty():
		return
	
	var active_employees = []
	for e in state.hr.employees:
		if e.active:
			active_employees.append(e)
	employees_count_badge.text = "%d zamestnancov" % active_employees.size()
	
	# Top stats strip
	var left_seconds = int(maxf(0.0, ceil(FoundryEngine.next_pay(state) - state.clock)))
	next_pay_label.text = "%d min %d s" % [left_seconds / 60, left_seconds % 60]
	accrued_pay_label.text = Format.cash(state.payroll.accrued)
	
	var weekly_total = 0.0
	for e in active_employees:
		weekly_total += FoundryEngine.weekly_pay(e)
	weekly_pay_label.text = Format.cash(weekly_total)
	
	debt_label.text = Format.cash(state.payroll.debt)
	
	# Debt alert
	if state.payroll.debt > 0:
		debt_alert.visible = true
		debt_alert_label.text = "Nové dávky stoja do doplatenia miezd. Dlžné mzdy: %s" % Format.cash(state.payroll.debt)
		var payable = mini(int(state.money), int(state.payroll.debt))
		btn_pay_debt.text = "Doplatiť %s" % Format.cash(payable)
		btn_pay_debt.disabled = _is_paused() or state.money <= 0
	else:
		debt_alert.visible = false
		
	if active_tab == "overview":
		_update_overview_tab(active_employees, force)
	elif active_tab == "hire":
		_update_hire_tab(force)
	elif active_tab == "payroll":
		_update_payroll_tab(force)

func _get_office_status(e: Dictionary) -> String:
	var state = _get_state()
	if not e.get("active", false):
		return "Ukončený pomer"
	for c in state.hr.covers:
		if c.employeeId == e.id and c.until > state.clock:
			return "Nadčas"
	var positions = FoundryEngine.positions(state)
	var pos = null
	for p in positions:
		if p.key == e.position:
			pos = p
			break
	if pos == null or not FoundryEngine.position_active(state, pos):
		return "Voľno"
	var att = state.hr.attendance.get(pos.key, {})
	if att.get("absent", false):
		return "Neprišiel na smenu"
	return "V práci"

func _update_overview_tab(active_employees: Array, force: bool = false) -> void:
	var state = _get_state()
	var cur_shift = FoundryEngine.shift(state)
	var crew_info = Constants.CREWS[cur_shift]
	shift_title_label.text = "Aktuálna smena · %s (%s)" % [crew_info.shift, crew_info.hours]
	
	var paused = _is_paused()
	var overview_key = "%d:%d:%d:%d:%s:%d:%s" % [
		state.get("revision", 0), cur_shift, active_employees.size(),
		state.hr.covers.size(), str(paused), int(state.money), employee_position_key
	]
	if not force and overview_key == _last_overview_key:
		return
	_last_overview_key = overview_key
	
	# Missing list
	var old_scroll = missing_workers_list.get_node_or_null("VacancyScroll") as ScrollContainer
	var scroll_position = old_scroll.scroll_horizontal if old_scroll != null else 0
	for child in missing_workers_list.get_children():
		missing_workers_list.remove_child(child)
		child.queue_free()
		
	var positions = FoundryEngine.positions(state)
	var missing = []
	for p in positions:
		if FoundryEngine.position_active(state, p) and FoundryEngine.duty(state, p.role, p.slot) == null:
			missing.append(p)
			
	if missing.is_empty():
		var ok_lbl = Label.new()
		ok_lbl.text = "✓ Všetky pracoviská aktuálnej smeny majú obsluhu."
		ok_lbl.modulate = Color(0.4, 0.9, 0.6)
		missing_workers_list.add_child(ok_lbl)
	else:
		var vacancy_scroll = ScrollContainer.new()
		vacancy_scroll.name = "VacancyScroll"
		vacancy_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vacancy_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vacancy_scroll.follow_focus = true
		var vacancy_row = BoxContainer.new()
		vacancy_row.add_theme_constant_override("separation", 8)
		vacancy_scroll.add_child(vacancy_row)
		missing_workers_list.add_child(vacancy_scroll)
		for p in missing:
			var e = FoundryEngine.assigned(state, p.key)
			var card = PanelContainer.new()
			card.mouse_filter = Control.MOUSE_FILTER_PASS
			var style = StyleBoxFlat.new()
			style.bg_color = Color("#3c3631")
			style.border_color = Color("#b17e5c")
			style.set_border_width_all(1)
			style.set_corner_radius_all(9)
			style.set_content_margin_all(10 if e == null else 18)
			card.add_theme_stylebox_override("panel", style)
			
			var card_box: BoxContainer = VBoxContainer.new() if e == null else BoxContainer.new()
			card_box.add_theme_constant_override("separation", 16)
			
			var info_box = VBoxContainer.new()
			info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var title_l = Label.new()
			title_l.text = p.label
			title_l.add_theme_font_size_override("font_size", 14)
			var sub_l = Label.new()
			sub_l.text = ("%s neprišiel na smenu." % e.name) if e != null else "Pracovné miesto je voľné."
			sub_l.modulate = Color(0.9, 0.7, 0.7)
			info_box.add_child(title_l)
			info_box.add_child(sub_l)
			if e != null:
				card_box.add_child(info_box)
			else:
				info_box.free()
			
			var actions_box: BoxContainer = VBoxContainer.new() if e == null else BoxContainer.new()
			actions_box.add_theme_constant_override("separation", 8)
			var choices = FoundryEngine.overtime_choices(state, p.key)
			for c in choices:
				var btn_c = Button.new()
				var mult = 1.5 if cur_shift == 2 else 1.0
				var cost = c.salary * mult * 1.5
				btn_c.text = "Zavolať %s · %s" % [c.name, Format.cash(cost)]
				btn_c.disabled = paused
				var c_id = c.id
				var p_key = p.key
				btn_c.pressed.connect(func():
					_execute({ "type": "personnel", "action": "overtime", "position": p_key, "employeeId": c_id })
					_update_view(true)
				)
				actions_box.add_child(btn_c)
			
			if e == null:
				var btn_rec = Button.new()
				btn_rec.text = p.label
				btn_rec.tooltip_text = "Vybrať uchádzača · " + p.label
				btn_rec.set_meta("vacancy_position", p.key)
				btn_rec.custom_minimum_size = Vector2(116, 100)
				_style_position_icon(btn_rec, p.role)
				var p_key = p.key
				btn_rec.pressed.connect(func():
					recruit_position_key = p_key
					_switch_tab("hire")
				)
				card_box.add_child(btn_rec)
				
			if actions_box.get_child_count() > 0:
				card_box.add_child(actions_box)
			else:
				actions_box.free()
			card.add_child(card_box)
			if e == null:
				vacancy_row.add_child(card)
			else:
				missing_workers_list.add_child(card)
		vacancy_scroll.visible = vacancy_row.get_child_count() > 0
		vacancy_scroll.set_deferred("scroll_horizontal", scroll_position)
			
	# Active employees grid
	_sync_employee_position_selection()
	for child in employees_list.get_children():
		employees_list.remove_child(child)
		child.queue_free()
	var selected_parts = employee_position_key.split(":")
	for e in active_employees:
		if selected_parts.size() < 2 or e.role != selected_parts[0] or int(e.slot) != int(selected_parts[1]):
			continue
		var position = {"label": e.position, "hours": "", "role": e.role}
		for pos in positions:
			if pos.key == e.position:
				position = pos
				break
		var card = PersonnelCard.new()
		card.configure(e, position, state, false, _get_office_status(e), paused)
		var emp_id = e.id
		card.action_button.pressed.connect(func():
			_execute({"type": "personnel", "action": "dismiss", "employeeId": emp_id})
			_update_view(true)
		)
		employees_list.add_child(card)
	employee_empty_label.visible = employees_list.get_child_count() == 0
	_resize_personnel_grids()

func _update_hire_tab(force: bool = false) -> void:
	var state = _get_state()
	if state == null or state.is_empty():
		return
		
	var paused = _is_paused()
	var cur_shift = FoundryEngine.shift(state)
	var hire_key = "%d:%s:%d:%s" % [state.get("revision", 0), recruit_position_key, cur_shift, str(paused)]
	if not force and hire_key == _last_hire_key:
		return
	_last_hire_key = hire_key
	
	var positions = FoundryEngine.positions(state)
	var selected_pos = null
	for p in positions:
		if p.key == recruit_position_key:
			selected_pos = p
			break
	if selected_pos == null and not positions.is_empty():
		selected_pos = positions[0]
		recruit_position_key = selected_pos.key
		
	_sync_position_selection()
		
	if not FoundryEngine.has_defect(selected_pos.role):
		recruit_formula_label.text = "Mzdu ovplyvňuje spoľahlivosť: nižšia absencia = vyššia mzda."
	else:
		recruit_formula_label.text = "Mzdu ovplyvňuje kvalita aj absencia. Riziko nepodarku sa uplatňuje pri obsluhe odstredivky."
		
	for child in recruit_shifts_list.get_children():
		recruit_shifts_list.remove_child(child)
		child.queue_free()
		
	var shifts = []
	for p in positions:
		if p.role == selected_pos.role and p.slot == selected_pos.slot:
			shifts.append(p)
			
	for p in shifts:
		var shift_box = VBoxContainer.new()
		shift_box.add_theme_constant_override("separation", 8)
		
		var shift_title = Label.new()
		var crew_title = "Nočný dohľad" if (p.role == "foreman" and p.crew == 1) else ("Denný dohľad" if p.role == "foreman" else Constants.CREWS[p.crew].shift)
		shift_title.text = "%s · %s" % [p.hours, crew_title]
		shift_title.add_theme_font_size_override("font_size", 15)
		shift_box.add_child(shift_title)
		
		var assigned_emp = FoundryEngine.assigned(state, p.key)
		if assigned_emp != null:
			var occ_lbl = Label.new()
			occ_lbl.text = "✓ Obsadené: %s · %s / smena" % [assigned_emp.name, Format.cash(FoundryEngine.regular_shift_pay(assigned_emp))]
			occ_lbl.modulate = Color(0.4, 0.9, 0.6)
			shift_box.add_child(occ_lbl)
		else:
			var cand_grid = GridContainer.new()
			cand_grid.set_meta("responsive_columns", true)
			cand_grid.add_to_group("personnel_grids")
			cand_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cand_grid.add_theme_constant_override("h_separation", 16)
			cand_grid.add_theme_constant_override("v_separation", 16)
			cand_grid.add_theme_constant_override("separation", 12)
			var candidates = state.hr.candidates.get(p.key, [])
			
			for c in candidates:
				var c_card = PersonnelCard.new()
				c_card.configure(c, p, state, true, "", paused)
				var c_id = c.id
				var p_key = p.key
				c_card.action_button.pressed.connect(func():
					_execute({"type": "personnel", "action": "hire", "position": p_key, "candidateId": c_id})
					_update_view(true)
				)
				cand_grid.add_child(c_card)

			shift_box.add_child(cand_grid)
			
		recruit_shifts_list.add_child(shift_box)
	_resize_personnel_grids()

func _update_payroll_tab(force: bool = false) -> void:
	var state = _get_state()
	if state == null or state.is_empty():
		return
		
	var payroll_key = "%d:%d:%d" % [
		state.get("revision", 0),
		state.hr.lines.size(),
		state.payroll.history.size()
	]
	if not force and payroll_key == _last_payroll_key:
		return
	_last_payroll_key = payroll_key
	
	for child in payroll_lines_table.get_children():
		child.queue_free()
		
	var lines = state.hr.lines.values()
	if lines.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Zatiaľ nie sú žiadne nové mzdové položky v tomto týždni."
		empty_lbl.modulate = Color(0.7, 0.7, 0.7)
		payroll_lines_table.add_child(empty_lbl)
	else:
		# Table Header
		var header_row = BoxContainer.new()
		var col1 = Label.new(); col1.text = "Pracovník"; col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col2 = Label.new(); col2.text = "Riadna mzda"; col2.custom_minimum_size = Vector2(100, 0)
		var col3 = Label.new(); col3.text = "Nadčas"; col3.custom_minimum_size = Vector2(100, 0)
		var col4 = Label.new(); col4.text = "Odstupné"; col4.custom_minimum_size = Vector2(100, 0)
		header_row.add_child(col1); header_row.add_child(col2); header_row.add_child(col3); header_row.add_child(col4)
		payroll_lines_table.add_child(header_row)
		
		for line in lines:
			var row = BoxContainer.new()
			var l1 = Label.new(); l1.text = line.name; l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var l2 = Label.new(); l2.text = Format.cash(line.normal); l2.custom_minimum_size = Vector2(100, 0)
			var l3 = Label.new(); l3.text = Format.cash(line.overtime); l3.custom_minimum_size = Vector2(100, 0)
			var l4 = Label.new(); l4.text = Format.cash(line.severance); l4.custom_minimum_size = Vector2(100, 0)
			row.add_child(l1); row.add_child(l2); row.add_child(l3); row.add_child(l4)
			payroll_lines_table.add_child(row)
			
	# History list
	for child in payroll_history_list.get_children():
		child.queue_free()
		
	if state.payroll.history.is_empty():
		var no_hist = Label.new()
		no_hist.text = "Žiadna predchádzajúca výplata."
		payroll_history_list.add_child(no_hist)
	else:
		for h in state.payroll.history:
			var hist_card = PanelContainer.new()
			hist_card.mouse_filter = Control.MOUSE_FILTER_PASS
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.16, 0.18, 0.9)
			style.border_color = Color(0.2, 0.3, 0.35, 1.0)
			style.set_border_width_all(1)
			style.set_corner_radius_all(9)
			style.set_content_margin_all(18)
			hist_card.add_theme_stylebox_override("panel", style)
			
			var hvbox = VBoxContainer.new()
			var day_num = FoundryEngine.day({ "clock": h.clock })
			var title_lbl = Label.new()
			title_lbl.text = "Deň %d · Nárok %s · Vyplatené %s" % [day_num, Format.cash(h.due), Format.cash(h.paid)]
			title_lbl.modulate = Color(0.957, 0.808, 0.533, 1)
			hvbox.add_child(title_lbl)
			
			var emps = h.get("employees", [])
			if not emps.is_empty():
				for el in emps:
					var emp_lbl = Label.new()
					emp_lbl.text = "  • %s · riadna %s · nadčas %s · odstupné %s" % [
						el.name, Format.cash(el.normal), Format.cash(el.overtime), Format.cash(el.severance)
					]
					emp_lbl.add_theme_font_size_override("font_size", 11)
					hvbox.add_child(emp_lbl)
					
			hist_card.add_child(hvbox)
			payroll_history_list.add_child(hist_card)

func _resize_personnel_grids() -> void:
	recruit_position_buttons.columns = 2 if display_mode.mobile else maxi(1, recruit_position_buttons.get_child_count())
	employee_position_buttons.columns = 2 if display_mode.mobile else maxi(1, employee_position_buttons.get_child_count())
	# Read the viewport, so shrinking can remove columns despite grid minimum sizes.
	var available = maxf(280, $VBox/ScrollContent.size.x - 24)
	var count = 1 if display_mode.mobile else maxi(1, int((available + 16) / 296))
	for grid in get_tree().get_nodes_in_group("personnel_grids"):
		if is_ancestor_of(grid):
			grid.columns = count
