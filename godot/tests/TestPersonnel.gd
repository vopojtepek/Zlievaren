class_name TestPersonnel
extends RefCounted

var n: int = 0

func assert_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		printerr("FAIL: ", msg, " | Expected: ", expected, " | Got: ", actual)
		assert(false)

func assert_true(cond: bool, msg: String = "") -> void:
	if not cond:
		printerr("FAIL: ", msg, " | Condition is false")
		assert(false)

func assert_near(a: float, b: float, eps: float = 1e-6, msg: String = "") -> void:
	if abs(a - b) >= eps:
		printerr("FAIL: ", msg, " | ", a, " != ", b)
		assert(false)

func copy_state(s: Dictionary) -> Dictionary:
	return FoundryEngine.restore(JSON.stringify(s))

func key(role: String, crew: int = 0, slot: int = -1) -> String:
	return FoundryEngine.position_key(role, crew, slot)

func ok_action(s: Dictionary, c: Dictionary) -> Dictionary:
	var cmd: Dictionary = c.duplicate(true)
	cmd["type"] = "personnel"
	var r: Dictionary = FoundryEngine.perform(s, cmd)
	assert_true(r.ok, r.get("message", "personnel command failed"))
	return r

func setup() -> Dictionary:
	var old: Dictionary = FoundryEngine.fresh()
	old.raw = { "iron": 36, "steel": 15, "copper": 8, "tin": 3, "zinc": 16 }
	old.incoming = FoundryEngine.empty_raw()
	old.version = 11
	old.erase("hr")
	var s: Dictionary = FoundryEngine.restore(JSON.stringify(old))
	s.money = 100000
	s.rng = 1000
	s.hr.rng = 202
	for e in s.hr.employees:
		e.absence = 1.0
	for mat in s.incoming.keys():
		var q = s.incoming[mat]
		if q > 0:
			var store_res = FoundryEngine.perform(s, { "type": "store", "material": mat, "quantity": q })
			assert_true(store_res.ok)
	return s

func hire(s: Dictionary, role: String = "operator", crew: int = 0, slot: int = 0) -> Dictionary:
	var p: String = key(role, crew, slot)
	var c: Dictionary = s.hr.candidates[p][0]
	ok_action(s, { "action": "hire", "position": p, "candidateId": c.id })
	return FoundryEngine.assigned(s, p)

func absent(s: Dictionary, role: String, crew: Variant = null, slot: int = -1) -> Dictionary:
	var crw: int = int(crew) if crew != null else FoundryEngine.shift(s)
	var p: String = key(role, crw, slot)
	var e: Dictionary = FoundryEngine.assigned(s, p)
	var denom: float = 90.0 if role == "foreman" else 60.0
	var cycle: int = int(floor((s.clock - 45.0 + 1e-8) / denom))
	s.hr.attendance[p] = {
		"cycle": cycle,
		"employeeId": e.id,
		"absent": true
	}
	return e

func run_all() -> bool:
	n = 0

	# Test 1
	var s1 = setup()
	assert_eq(s1.hr.employees.size(), 11)
	assert_eq(FoundryEngine.positions(s1).size(), 17)
	for pos_k in s1.hr.candidates.keys():
		var list: Array = s1.hr.candidates[pos_k]
		assert_true(list.size() >= 2 and list.size() <= 5)
		var role_k = pos_k.split(":")[0]
		for c in list:
			if FoundryEngine.has_defect(role_k):
				assert_true(c.defect >= 1 and c.defect <= 15)
			else:
				assert_true(not c.has("defect"))
			assert_true(c.absence >= 0.5 and c.absence <= 10.0)
	assert_eq(JSON.stringify(copy_state(s1).hr.candidates), JSON.stringify(s1.hr.candidates))
	print("OK all existing roles have individual records and every vacancy has 2–5 stable, differently paid candidates")
	n += 1

	# Test 2
	var s2 = setup()
	var pos2 = key("operator", 0, 0)
	var c2 = s2.hr.candidates[pos2][-1]
	var money2 = s2.money
	assert_eq(FoundryEngine.perform(s2, { "type": "employment", "action": "hire", "slot": 0, "crew": 0 }).ok, false)
	ok_action(s2, { "action": "hire", "position": pos2, "candidateId": c2.id })
	var e2 = FoundryEngine.assigned(s2, pos2)
	assert_eq(e2.salary, c2.salary)
	assert_eq(e2.defect, c2.defect)
	assert_eq(e2.absence, c2.absence)
	assert_eq(e2.hiredAt, s2.clock)
	assert_eq(s2.money, money2)
	assert_eq(FoundryEngine.duty(s2, "operator", 0).id, e2.id)
	assert_eq(JSON.stringify(copy_state(s2).hr.employees), JSON.stringify(s2.hr.employees))
	assert_eq(FoundryEngine.perform(s2, { "type": "personnel", "action": "hire", "position": pos2, "candidateId": c2.id }).ok, false)
	print("OK hire requires a listed candidate; negotiated salary and skills persist for the chosen position")
	n += 1

	# Test 3
	for role3 in ["ladle", "furnace", "warehouse", "foreman"]:
		var s3 = setup()
		var old3 = FoundryEngine.assigned(s3, key(role3))
		ok_action(s3, { "action": "dismiss", "employeeId": old3.id })
		assert_eq(FoundryEngine.duty(s3, role3), null)
		assert_true(s3.hr.candidates[key(role3)].size() >= 2)
		var e3 = hire(s3, role3, 0, -1)
		assert_eq(FoundryEngine.duty(s3, role3).id, e3.id)
	var s3_b = setup()
	assert_eq(FoundryEngine.regular_shift_pay(FoundryEngine.assigned(s3_b, key("foreman", 1))), 40.0)
	print("OK each profession can be dismissed and recruited, including both 12-hour foremen")
	n += 1

	# Test 4
	var s4 = setup()
	s4.clock = 104.99
	FoundryEngine.assigned(s4, key("ladle", 1)).absence = 10.0
	s4.hr.rng = 2000
	FoundryEngine.tick(s4, 0.01)
	var e4 = FoundryEngine.assigned(s4, key("ladle", 1))
	var rng4 = s4.hr.rng
	assert_eq(FoundryEngine.duty(s4, "ladle"), null)
	assert_eq(s4.hr.attendance[e4.position].absent, true)
	var r4 = copy_state(s4)
	assert_eq(r4.hr.rng, rng4)
	FoundryEngine.tick(r4, 0.2)
	assert_eq(r4.hr.rng, rng4)
	assert_eq(FoundryEngine.duty(r4, "ladle"), null)
	assert_true(FoundryEngine.overtime_choices(r4, e4.position).size() > 0)
	print("OK absence is rolled once at shift start and survives reload, actions and small ticks")
	n += 1

	# Test 5
	var s5 = setup()
	s5.clock = 105.0
	FoundryEngine.tick(s5, 0.01)
	var missing5 = absent(s5, "ladle", 1)
	var sub5 = FoundryEngine.assigned(s5, key("ladle", 0))
	var before5 = FoundryEngine.employee(s5, missing5.id)
	var initial5 = s5.hr.lines.get(missing5.id, {}).get("normal", 0.0)
	ok_action(s5, { "action": "overtime", "position": missing5.position, "employeeId": sub5.id })
	assert_eq(FoundryEngine.duty(s5, "ladle").id, sub5.id)
	FoundryEngine.tick(s5, 10.0)
	assert_near(s5.hr.lines[sub5.id].overtime, sub5.salary * 10.0 / 60.0 * 1.5)
	assert_near(s5.hr.lines.get(before5.id, {}).get("normal", 0.0), initial5)
	assert_eq(FoundryEngine.perform(s5, { "type": "personnel", "action": "overtime", "position": missing5.position, "employeeId": sub5.id }).ok, false)
	print("OK absent workers earn nothing; manually called replacement earns 50% overtime only for actual time")
	n += 1

	# Test 6
	var s6 = setup()
	s6.clock = 165.0
	FoundryEngine.tick(s6, 0.01)
	var missing6 = absent(s6, "warehouse", 2)
	var sub6 = FoundryEngine.assigned(s6, key("warehouse", 0))
	ok_action(s6, { "action": "overtime", "position": missing6.position, "employeeId": sub6.id })
	FoundryEngine.tick(s6, 20.0)
	assert_near(s6.hr.lines[sub6.id].overtime, sub6.salary * 20.0 / 60.0 * 1.5 * 1.5)
	print("OK night overtime applies both the night premium and the overtime multiplier")
	n += 1

	# Test 7
	var s7 = setup()
	FoundryEngine.act(s7, 1, "buy")
	var sub7 = hire(s7, "operator", 1, 0)
	var missing7 = key("operator", 0, 0)
	var other7 = key("operator", 0, 1)
	assert_eq(FoundryEngine.perform(s7, { "type": "personnel", "action": "overtime", "position": missing7, "employeeId": FoundryEngine.duty(s7, "warehouse").id }).ok, false)
	ok_action(s7, { "action": "overtime", "position": missing7, "employeeId": sub7.id })
	assert_eq(FoundryEngine.perform(s7, { "type": "personnel", "action": "overtime", "position": other7, "employeeId": sub7.id }).ok, false)
	assert_eq(FoundryEngine.perform(s7, { "type": "personnel", "action": "overtime", "position": missing7, "employeeId": FoundryEngine.duty(s7, "ladle").id }).ok, false)
	print("OK substitution rejects wrong professions, on-duty staff and employees already covering another machine")
	n += 1

	# Test 8
	var s8 = setup()
	var sub8 = hire(s8, "operator", 1, 0)
	ok_action(s8, { "action": "overtime", "position": key("operator", 0, 0), "employeeId": sub8.id })
	FoundryEngine.tick(s8, 15.0)
	var r8 = copy_state(s8)
	assert_eq(JSON.stringify(r8.hr.covers), JSON.stringify(s8.hr.covers))
	FoundryEngine.tick(r8, 45.0)
	assert_eq(r8.hr.covers.size(), 0)
	var earned8 = r8.hr.lines[sub8.id].overtime
	FoundryEngine.tick(r8, 1.0)
	assert_near(r8.hr.lines[sub8.id].overtime, earned8)
	print("OK overtime persists on reload and expires at the target shift boundary")
	n += 1

	# Test 9
	var s9 = setup()
	var e9 = FoundryEngine.assigned(s9, key("warehouse", 2))
	var cases9 = [[0.99, 0], [1.0, 1], [1.99, 1], [2.0, 2], [2.99, 2], [3.0, 4], [7.0, 4]]
	for c_pair in cases9:
		var months = c_pair[0]
		var multiple = c_pair[1]
		s9.clock = e9.hiredAt + months * Constants.MONTH
		assert_eq(FoundryEngine.severance(s9, e9), int(round(FoundryEngine.weekly_pay(e9) * multiple)))
	var foreman9 = FoundryEngine.assigned(s9, key("foreman", 1))
	s9.clock = foreman9.hiredAt + 3.0 * Constants.MONTH
	assert_eq(FoundryEngine.severance(s9, foreman9), 1120)
	print("OK severance thresholds are exact at 28 / 56 / 84 days and cap at four weeks")
	n += 1

	# Test 10
	var s10 = setup()
	var e10 = FoundryEngine.duty(s10, "warehouse")
	FoundryEngine.tick(s10, 10.0)
	var wage10 = s10.hr.lines[e10.id].normal
	s10.clock = e10.hiredAt + 2.0 * Constants.MONTH
	var extra10 = FoundryEngine.severance(s10, e10)
	var cash10 = s10.money
	var before10 = s10.payroll.accrued
	ok_action(s10, { "action": "dismiss", "employeeId": e10.id })
	assert_eq(s10.money, cash10)
	assert_near(s10.payroll.accrued, before10 + extra10)
	assert_near(s10.hr.lines[e10.id].normal, wage10)
	assert_eq(s10.hr.lines[e10.id].severance, extra10)
	assert_eq(FoundryEngine.perform(s10, { "type": "personnel", "action": "dismiss", "employeeId": e10.id }).ok, false)
	hire(s10, "warehouse", 0, -1)
	var r10 = copy_state(s10)
	assert_eq(r10.hr.lines[e10.id].severance, extra10)
	FoundryEngine.tick(r10, FoundryEngine.next_pay(r10) - r10.clock)
	var line10: Variant = null
	for l in r10.payroll.history[0].employees:
		if l.employeeId == e10.id:
			line10 = l
			break
	assert_true(line10 != null)
	assert_eq(line10.severance, extra10)
	assert_near(line10.normal, wage10)
	assert_true(not r10.hr.lines.has(e10.id))
	print("OK dismissal adds severance once to weekly payroll and preserves accrued wages after replacement")
	n += 1

	# Test 11
	for role11 in ["ladle", "furnace", "foreman", "operator"]:
		var s11_sub = setup()
		hire(s11_sub)
		absent(s11_sub, role11, 0, 0 if role11 == "operator" else -1)
		assert_true(FoundryEngine.can_cast(s11_sub, 0) != "")
	var s11 = setup()
	absent(s11, "warehouse")
	assert_eq(FoundryEngine.perform(s11, { "type": "store", "material": "iron", "quantity": 1 }).ok, false)
	s11.goods["iron_pipe"] = 1
	assert_true(FoundryEngine.can_wash(s11) != "")
	s11.goods["ring"] = 1
	assert_eq(FoundryEngine.perform(s11, { "type": "trade", "item": "goods:ring", "side": "sell", "quantity": 1 }).ok, false)
	print("OK absence and vacancies block only dependent jobs; replacements restore operation")
	n += 1

	# Test 12
	var s12 = setup()
	hire(s12)
	for e in s12.hr.employees:
		e.defect = 1
	var m12 = s12.machines[0]
	assert_near(FoundryEngine.total_failure_risk(s12, m12, 0), 0.31)
	for role12 in ["ladle", "furnace", "operator"]:
		FoundryEngine.duty(s12, role12, 0 if role12 == "operator" else -1).defect = 15
	assert_near(FoundryEngine.total_failure_risk(s12, m12, 0), 0.45)
	FoundryEngine.duty(s12, "warehouse").defect = 15
	assert_near(FoundryEngine.total_failure_risk(s12, m12, 0), 0.45)
	var m12_ring = m12.duplicate(true)
	m12_ring["product"] = "ring"
	assert_eq(FoundryEngine.total_failure_risk(s12, m12_ring, 0), 0.0)
	print("OK quality adds machine and operator risk and ignores other roles")
	n += 1

	# Test 13
	var s13 = setup()
	var e13 = hire(s13)
	s13.clock = 100.0
	assert_eq(FoundryEngine.act(s13, 0, "cast").ok, true)
	assert_eq(FoundryEngine.perform(s13, { "type": "personnel", "action": "dismiss", "employeeId": e13.id }).ok, false)
	FoundryEngine.tick(s13, 4.0)
	var pan13 = FoundryEngine.employee(s13, s13.delivery.employeeId)
	assert_eq(FoundryEngine.perform(s13, { "type": "personnel", "action": "dismiss", "employeeId": pan13.id }).ok, false)
	var r13 = copy_state(s13)
	FoundryEngine.tick(r13, 28.0)
	assert_eq(r13.machines[0].state, "ready")
	assert_eq(r13.goods["iron_pipe"], 0)
	print("OK busy employees cannot be dismissed and in-flight work survives shift handover and reload")
	n += 1

	# Test 14
	var s14 = setup()
	s14.version = 11
	s14.operators[0][0] = true
	s14.clock = 8000.0
	s14.payroll.accrued = 123.0
	s14.payroll.debt = 20
	s14.erase("hr")
	var r14 = copy_state(s14)
	assert_eq(r14.money, s14.money)
	assert_eq(r14.payroll.accrued, 123.0)
	assert_eq(r14.payroll.debt, 20)
	assert_eq(r14.hr.lines.legacy.normal, 123.0)
	assert_eq(FoundryEngine.assigned(r14, key("operator", 0, 0)).name, "Boris")
	for e in r14.hr.employees:
		assert_eq(e.hiredAt, 8000.0)
	assert_eq(JSON.stringify(copy_state(r14).hr), JSON.stringify(r14.hr))
	print("OK v11 saves retain workers, money and wages without inventing past tenure or back-charging")
	n += 1

	# Test 15
	var s15 = setup()
	var e15 = hire(s15)
	e15.salary = 37.0
	e15.absence = 1.0
	s15.hr.rng = 202
	FoundryEngine.tick(s15, 60.0)
	assert_near(s15.hr.lines[e15.id].normal, 37.0)
	var r15 = copy_state(s15)
	assert_eq(FoundryEngine.employee(r15, e15.id).salary, 37.0)
	FoundryEngine.tick(r15, FoundryEngine.next_pay(r15) - r15.clock)
	var h15 = r15.payroll.history[0]
	var line15: Variant = null
	for l in h15.employees:
		if l.employeeId == e15.id:
			line15 = l
			break
	assert_true(line15 != null)
	assert_near(line15.normal, 37.0 * 7.0)
	var re_h15 = copy_state(r15).payroll.history[0]
	var re_line15: Variant = null
	for l in re_h15.employees:
		if l.employeeId == e15.id:
			re_line15 = l
			break
	assert_eq(re_line15.name, e15.name)
	print("OK weekly payments use actual negotiated salaries and retain employee names in history after reload")
	n += 1

	# Test 16
	var s16 = setup()
	hire(s16)
	var a16 = copy_state(s16)
	var b16 = copy_state(s16)
	FoundryEngine.tick(a16, 1260.0)
	for i in range(12600):
		FoundryEngine.tick(b16, 0.1)
	assert_eq(a16.hr.rng, b16.hr.rng)
	assert_eq(a16.payroll.paid, b16.payroll.paid)
	assert_eq(a16.money, b16.money)
	assert_eq(JSON.stringify(a16.hr.attendance), JSON.stringify(b16.hr.attendance))
	assert_near(a16.payroll.accrued, b16.payroll.accrued)
	print("OK large and small steps produce the same absences, payroll and overtime expiration")
	n += 1

	# Test 17
	var s17 = FoundryEngine.fresh()
	var names17 = []
	for e in s17.hr.employees:
		names17.append(e.name)
	assert_eq(names17, ["Mišo (Majster)", "Miro (Majster)"])
	assert_eq(s17.money, 1000)
	assert_eq(s17.hr.candidates.keys().size(), 15)
	assert_eq(FoundryEngine.duty(s17, "warehouse"), null)
	assert_eq(FoundryEngine.perform(s17, { "type": "store", "material": "iron", "quantity": 1 }).ok, false)
	assert_eq(JSON.stringify(copy_state(s17).hr.employees), JSON.stringify(s17.hr.employees))
	for role17 in ["ladle", "furnace", "warehouse"]:
		hire(s17, role17, 0, -1)
	hire(s17)
	assert_eq(FoundryEngine.act(s17, 0, "cast").ok, true)
	print("OK fresh games employ only the two foremen; every other position requires hiring")
	n += 1

	# Test 18
	for role18 in Constants.WAGES.keys():
		for d18 in range(1, 16):
			var a18 = 0.5
			while a18 <= 10.0:
				var v18 = FoundryEngine.candidate_salary(role18, d18, a18)
				if d18 > 1:
					if FoundryEngine.has_defect(role18):
						assert_true(FoundryEngine.candidate_salary(role18, d18 - 1, a18) > v18)
					else:
						assert_eq(FoundryEngine.candidate_salary(role18, d18 - 1, a18), v18)
				if a18 > 0.5:
					assert_true(FoundryEngine.candidate_salary(role18, d18, a18 - 0.5) > v18)
				assert_true(v18 >= float(Constants.WAGES[role18]) * 0.65 - 0.051 and v18 <= float(Constants.WAGES[role18]) * 1.55 + 0.051)
				a18 += 0.5
	var s18 = FoundryEngine.fresh()
	for p18 in FoundryEngine.positions(s18):
		var cands18 = s18.hr.candidates.get(p18.key, [])
		for c in cands18:
			assert_eq(c.salary, FoundryEngine.candidate_salary(p18.role, c.get("defect"), c.absence))
	var e18 = s18.hr.employees[0]
	e18.salary = 25.3
	var list18 = s18.hr.candidates.values()[0]
	list18[0].salary = 199.0
	var r18 = copy_state(s18)
	assert_eq(r18.hr.employees[0].salary, 25.3)
	assert_true(r18.hr.candidates.values()[0][0].salary != 199.0)
	print("OK salary strictly increases for either improved statistic and is independent of candidate order")
	n += 1

	print(str(n) + " personnel checks passed.")
	return true
