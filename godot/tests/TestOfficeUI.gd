class_name TestOfficeUI
extends RefCounted

var n: int = 0
var _tree: SceneTree = null

func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		printerr("FAIL: ", msg, " | Condition is false")
		assert(false)

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		printerr("FAIL: ", msg, " | Expected: ", expected, " | Got: ", actual)
		assert(false)

func run_all(tree: SceneTree = null) -> bool:
	_tree = tree
	print("--- Running TestOfficeUI ---")
	test_office_initialization_and_positions()
	test_hire_buttons_stability_under_ticks()
	test_hire_employee_click_and_state_update()
	test_navigation_from_overview_select_candidate()
	test_vacancy_updates_and_overtime()
	test_overtime_calling()
	test_dismiss_employee()
	test_pay_debt()
	test_toast_manager()
	print(str(n) + " Office UI checks passed.")
	return true

func _create_office(s: Dictionary) -> Control:
	var office_scene = load("res://src/ui/office/OfficeView.tscn")
	var office = office_scene.instantiate()
	office.current_state = s
	
	# Add to main loop root so _ready and theme/hierarchy initialize properly
	var root: Window = null
	if _tree != null:
		root = _tree.root
	elif Engine.get_main_loop() != null and Engine.get_main_loop() is SceneTree:
		root = (Engine.get_main_loop() as SceneTree).root
		
	if root != null:
		root.add_child(office)
	return office

func _cleanup(office: Node) -> void:
	if office != null and office.is_inside_tree():
		office.get_parent().remove_child(office)
		office.free()

func test_office_initialization_and_positions() -> void:
	var s = FoundryEngine.fresh()
	var office = _create_office(s)
	
	office._switch_tab("hire")
	office._populate_recruit_positions()
	
	assert_true(office.cached_position_keys.size() >= 5, "Has position keys cached")
	assert_eq(office.cached_position_keys.size(), office.recruit_position_buttons.get_child_count(), "Icon count matches keys")
	
	# Verify standard jobs are present in dropdown
	var found_ladle = false
	var found_furnace = false
	var found_warehouse = false
	for k in office.cached_position_keys:
		if k.begins_with("ladle:"):
			found_ladle = true
		elif k.begins_with("furnace:"):
			found_furnace = true
		elif k.begins_with("warehouse:"):
			found_warehouse = true
	assert_true(found_ladle and found_furnace and found_warehouse, "Standard positions present in dropdown")
	n += 3
	_cleanup(office)
	print("OK office positions discovered and populated in dropdown")

func test_hire_buttons_stability_under_ticks() -> void:
	var s = FoundryEngine.fresh()
	var office = _create_office(s)
	office._switch_tab("hire")
	
	# Find hire buttons
	var hire_btns = []
	for node in office.find_children("*", "Button", true, false):
		if node.text == "Prijať":
			hire_btns.append(node)
			
	assert_true(hire_btns.size() > 0, "Candidate hire buttons generated")
	var first_btn: Button = hire_btns[0]
	var btn_id: int = first_btn.get_instance_id()
	
	# Simulate 15 physics frames (like during a player's mouse click)
	for i in range(15):
		office._on_tick(s, 0.016)
		
	assert_true(first_btn.is_inside_tree(), "Button is still inside the tree")
	assert_true(not first_btn.is_queued_for_deletion(), "Button was not destroyed by ticks")
	assert_eq(first_btn.get_instance_id(), btn_id, "Button instance remained persistent across ticks")
	n += 4
	_cleanup(office)
	print("OK hire buttons remain stable and persistent across 60Hz ticks")

func test_hire_employee_click_and_state_update() -> void:
	var s = FoundryEngine.fresh()
	var office = _create_office(s)
	office._switch_tab("hire")
	
	var initial_emp_count = 0
	for e in s.hr.employees:
		if e.active:
			initial_emp_count += 1
			
	# Find a hire button
	var hire_btns = []
	for node in office.find_children("*", "Button", true, false):
		if node.text == "Prijať":
			hire_btns.append(node)
			
	assert_true(hire_btns.size() > 0, "Found hire buttons")
	var btn: Button = hire_btns[0]
	
	# Click the button
	btn.emit_signal("pressed")
	
	# Verify employee was hired
	var new_emp_count = 0
	for e in s.hr.employees:
		if e.active:
			new_emp_count += 1
	assert_eq(new_emp_count, initial_emp_count + 1, "Active employee count incremented by 1")
	
	# Verify UI re-rendered cleanly
	var labels_text = []
	for node in office.find_children("*", "Label", true, false):
		labels_text.append(node.text)
	
	var has_occupied_label = false
	for txt in labels_text:
		if txt.begins_with("✓ Obsadené:"):
			has_occupied_label = true
			break
	assert_true(has_occupied_label, "Shift now displays occupied status")
	n += 3
	_cleanup(office)
	print("OK clicking hire button successfully hires employee and updates UI")

func test_navigation_from_overview_select_candidate() -> void:
	var s = FoundryEngine.fresh()
	var office = _create_office(s)
	office._switch_tab("overview")
	
	# Each vacancy icon opens recruitment for its exact position.
	var select_btns = []
	for node in office.find_children("*", "Button", true, false):
		if node.has_meta("vacancy_position"):
			select_btns.append(node)
			
	assert_true(select_btns.size() > 0, "Missing worker has candidate selection button")
	var btn: Button = select_btns[0]
	var position_key = btn.get_meta("vacancy_position")
	btn.emit_signal("pressed")
	
	# Should now be in hire tab
	assert_eq(office.active_tab, "hire", "Active tab switched to hire")
	assert_eq(office.recruit_position_key, position_key, "Recruitment selects the clicked vacancy")
	assert_true(office.recruit_position_buttons.get_children().any(func(b): return b.button_pressed), "Icons synchronized with selected position")
	n += 3
	_cleanup(office)
	print("OK navigation from overview selects position and synchronizes dropdown")

func test_vacancy_updates_and_overtime() -> void:
	var s = FoundryEngine.fresh()
	s.clock = 45.0
	var pos0 = FoundryEngine.position_key("operator", 0, 0)
	var pos1 = FoundryEngine.position_key("operator", 1, 0)
	var candidate = s.hr.candidates[pos1][0]
	FoundryEngine.perform(s, {"type": "personnel", "action": "hire", "position": pos1, "candidateId": candidate.id})
	var office = _create_office(s)
	var vacancy_scroll = office.missing_workers_list.get_node("VacancyScroll")
	var overtime_buttons = vacancy_scroll.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Zavolať"))
	assert_true(not overtime_buttons.is_empty(), "Vacant position retains overtime action")
	var clock = office.get_node("/root/SimulationClock")
	var was_paused = clock.is_paused
	clock.is_paused = true
	office._update_view(true)
	vacancy_scroll = office.missing_workers_list.get_node("VacancyScroll")
	for button in vacancy_scroll.find_children("*", "Button", true, false):
		if button.text.begins_with("Zavolať"):
			assert_true(button.disabled, "Vacancy overtime is disabled during pause")
	clock.is_paused = was_paused
	candidate = s.hr.candidates[pos0][0]
	FoundryEngine.perform(s, {"type": "personnel", "action": "hire", "position": pos0, "candidateId": candidate.id})
	office._update_view(true)
	for button in office.missing_workers_list.find_children("*", "Button", true, false):
		assert_true(button.get_meta("vacancy_position", "") != pos0, "Hired position no longer has a vacancy icon")
	s.clock = 105.0
	office._update_view()
	for button in office.missing_workers_list.find_children("*", "Button", true, false):
		if button.has_meta("vacancy_position"):
			var position = FoundryEngine.positions(s).filter(func(p): return p.key == button.get_meta("vacancy_position"))[0]
			assert_true(FoundryEngine.position_active(s, position), "Vacancies follow the current shift")
	n += 4
	_cleanup(office)
	print("OK vacancies refresh after hiring and shift change, retaining guarded overtime actions")

func test_overtime_calling() -> void:
	var s = FoundryEngine.fresh()
	# First hire an operator for crew 0 and crew 1
	var pos0 = FoundryEngine.position_key("operator", 0, 0)
	var pos1 = FoundryEngine.position_key("operator", 1, 0)
	var c0 = s.hr.candidates[pos0][0]
	FoundryEngine.perform(s, { "type": "personnel", "action": "hire", "position": pos0, "candidateId": c0.id })
	var c1 = s.hr.candidates[pos1][0]
	FoundryEngine.perform(s, { "type": "personnel", "action": "hire", "position": pos1, "candidateId": c1.id })
	
	# Mark operator 0 as absent in attendance
	s.clock = 45.0
	var emp0 = FoundryEngine.assigned(s, pos0)
	s.hr.attendance[pos0] = { "cycle": 0, "employeeId": emp0.id, "absent": true }
	s.revision += 1
	
	var office = _create_office(s)
	office._switch_tab("overview")
	
	# Look for overtime button
	var ot_btns = []
	for node in office.find_children("*", "Button", true, false):
		if node.text.begins_with("Zavolať"):
			ot_btns.append(node)
			
	assert_true(ot_btns.size() > 0, "Found overtime button for absent position")
	var ot_btn: Button = ot_btns[0]
	ot_btn.emit_signal("pressed")
	
	# Verify overtime cover was registered
	assert_true(s.hr.covers.size() > 0, "Overtime cover registered in state")
	assert_eq(s.hr.covers[0].position, pos0, "Overtime cover matches position")
	n += 3
	_cleanup(office)
	print("OK overtime button successfully calls employee using correct employeeId")

func test_dismiss_employee() -> void:
	var s = FoundryEngine.fresh()
	var office = _create_office(s)
	office._switch_tab("overview")
	
	var dismiss_btns = []
	for node in office.find_children("*", "Button", true, false):
		if node.text.begins_with("Prepustiť"):
			dismiss_btns.append(node)
			
	assert_true(dismiss_btns.size() > 0, "Found dismiss button")
	var emp0 = s.hr.employees[0]
	assert_true(emp0.active, "Employee starts active")
	
	var btn: Button = dismiss_btns[0]
	btn.emit_signal("pressed")
	
	assert_true(not emp0.active, "Employee was dismissed")
	n += 3
	_cleanup(office)
	print("OK dismiss button successfully dismisses employee")

func test_pay_debt() -> void:
	var s = FoundryEngine.fresh()
	s.payroll.debt = 500
	s.money = 1000
	s.revision += 1
	
	var office = _create_office(s)
	office._switch_tab("overview")
	
	assert_true(office.debt_alert.visible, "Debt alert is visible")
	office.btn_pay_debt.emit_signal("pressed")
	
	assert_eq(s.payroll.debt, 0, "Debt was completely paid")
	assert_eq(s.money, 500, "Money deducted for debt payment")
	n += 3
	_cleanup(office)
	print("OK pay debt button successfully pays wages debt")

func test_toast_manager() -> void:
	var toast_scene = load("res://src/ui/panels/ToastManager.tscn")
	var toast_mgr = toast_scene.instantiate()
	var root: Window = _tree.root if _tree != null else null
	if root != null:
		root.add_child(toast_mgr)
	
	# Test both normal and error toasts
	toast_mgr._on_toast_requested("Prijatý Gabo Kováč.", false)
	toast_mgr._on_toast_requested("Nedostatok peňazí.", true)
	
	assert_eq(toast_mgr.container.get_child_count(), 2, "Two toasts added to ToastManager")
	var t0 = toast_mgr.container.get_child(0)
	var lbl0 = t0.get_child(0) as Label
	assert_eq(lbl0.text, "Prijatý Gabo Kováč.", "Toast message matches")
	assert_eq(lbl0.get_theme_font_size("font_size"), 14, "Toast font size override is set to 14")
	n += 4
	_cleanup(toast_mgr)
	print("OK toast manager creates toasts without font size errors")
