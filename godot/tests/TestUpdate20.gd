class_name TestUpdate20
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

func copy_state(s: Dictionary) -> Dictionary:
	return FoundryEngine.restore(JSON.stringify(s))

func hire(s: Dictionary, role: String, crew: int = 0) -> Dictionary:
	var pos_key: String = FoundryEngine.position_key(role, crew)
	var c = s.hr.candidates[pos_key][0]
	c.absence = 0.5
	var res = FoundryEngine.perform(s, { "type": "personnel", "action": "hire", "position": pos_key, "candidateId": c.id })
	assert_eq(res.ok, true)
	return FoundryEngine.assigned(s, pos_key)

func run_all() -> bool:
	n = 0

	# Test 1
	var s1 = FoundryEngine.fresh()
	assert_eq(JSON.stringify(s1.raw), JSON.stringify({ "iron": 60, "steel": 0, "copper": 0, "tin": 0, "zinc": 20 }))
	for inc_v in s1.incoming.values():
		assert_eq(inc_v, 0)
	assert_eq(JSON.stringify(copy_state(s1).raw), JSON.stringify(s1.raw))
	var old1 = copy_state(s1)
	old1.version = 13
	old1.raw = { "iron": 7, "steel": 2, "copper": 4, "tin": 1, "zinc": 3 }
	old1.incoming = { "iron": 1, "steel": 2, "copper": 0, "tin": 0, "zinc": 0 }
	assert_eq(JSON.stringify(copy_state(old1).raw), JSON.stringify(old1.raw))
	assert_eq(JSON.stringify(copy_state(old1).incoming), JSON.stringify(old1.incoming))
	print("OK fresh stocks are already stored; no other raw material or incoming delivery exists")
	n += 1

	# Test 2
	var s2 = FoundryEngine.fresh()
	s2.hr.rng = 202
	hire(s2, "warehouse")
	s2.goods["iron_pipe"] = 2
	assert_eq(FoundryEngine.perform(s2, { "type": "washer", "action": "start" }).ok, false)
	var e2 = hire(s2, "washer")
	s2.clock = 100.0
	s2.hr.rng = 202
	assert_eq(FoundryEngine.perform(s2, { "type": "washer", "action": "start" }).ok, true)
	FoundryEngine.tick(s2, 5.0)
	assert_eq(s2.washer.elapsed, 5.0)
	var cash2 = s2.money
	FoundryEngine.tick(s2, 10.0)
	assert_eq(s2.washer.elapsed, 5.0)
	assert_eq(s2.goods["clean_iron_pipe"], 0)
	var r2 = copy_state(s2)
	assert_eq(FoundryEngine.perform(r2, { "type": "personnel", "action": "overtime", "position": FoundryEngine.position_key("washer", 1), "employeeId": e2.id }).ok, true)
	FoundryEngine.tick(r2, 9.0)
	assert_eq(r2.goods["clean_iron_pipe"], 1)
	assert_eq(r2.goods["iron_pipe"], 1)
	assert_eq(r2.money, cash2)
	assert_true(r2.hr.lines[e2.id].overtime > 0.0)
	assert_eq(r2.washer.active, null)
	print("OK washer requires its own employee and pauses safely over shift changes, save and overtime")
	n += 1

	# Test 3
	var s3 = FoundryEngine.fresh()
	hire(s3, "warehouse")
	var e3 = hire(s3, "washer")
	s3.goods["ring"] = 1
	FoundryEngine.perform(s3, { "type": "washer", "action": "configure", "product": "ring" })
	FoundryEngine.perform(s3, { "type": "washer", "action": "start" })
	FoundryEngine.tick(s3, 4.0)
	assert_eq(FoundryEngine.perform(s3, { "type": "personnel", "action": "dismiss", "employeeId": e3.id }).ok, true)
	var money3 = s3.money
	FoundryEngine.tick(s3, 5.0)
	assert_eq(s3.washer.elapsed, 4.0)
	hire(s3, "washer")
	FoundryEngine.tick(s3, 10.0)
	assert_eq(s3.goods["clean_ring"], 1)
	assert_eq(s3.money, money3)
	print("OK washer absence or dismissal pauses a cycle and a replacement resumes without a second fee")
	n += 1

	# Test 4
	var s4 = FoundryEngine.fresh()
	s4.money = 10000
	assert_eq(FoundryEngine.perform(s4, { "type": "cnc", "slot": 0, "action": "toggle" }).ok, false)
	for i in range(6):
		var cash4 = s4.money
		assert_eq(FoundryEngine.perform(s4, { "type": "cnc", "slot": i, "action": "buy" }).ok, true)
		assert_eq(s4.money, cash4 - (500 + i * 250))
		assert_eq(FoundryEngine.perform(s4, { "type": "cnc", "slot": i, "action": "buy" }).ok, false)
		assert_eq(FoundryEngine.perform(s4, { "type": "cnc", "slot": i, "action": "toggle" }).ok, true)
	assert_eq(FoundryEngine.perform(s4, { "type": "cnc", "slot": 6, "action": "buy" }).ok, false)
	assert_eq(FoundryEngine.perform(s4, { "type": "cnc", "slot": 6, "action": "toggle" }).ok, false)
	var r4 = copy_state(s4)
	assert_eq(JSON.stringify(r4.cncOwned), JSON.stringify(s4.cncOwned))
	assert_eq(JSON.stringify(r4.cncPower), JSON.stringify(s4.cncPower))
	s4.cncOwned[6] = true
	s4.cncPower[6] = true
	assert_eq(copy_state(s4).cncOwned[6], false)
	var poor = FoundryEngine.fresh()
	poor.money = 499
	assert_eq(FoundryEngine.perform(poor, { "type": "cnc", "slot": 0, "action": "buy" }).ok, false)
	assert_eq(poor.money, 499)
	var old4 = copy_state(s4)
	old4.version = 13
	for x in copy_state(old4).cncOwned:
		assert_true(not x)
	print("OK CNC purchases use exact prices, cannot double charge, persist and never unlock AMADA")
	n += 1

	# Test 5
	var s5 = FoundryEngine.fresh()
	assert_eq(s5.hr.employees.size(), 2)
	var washer_positions = FoundryEngine.positions(s5).filter(func(p): return p.role == "washer")
	assert_eq(washer_positions.size(), 3)
	for crew in range(3):
		assert_true(s5.hr.candidates[FoundryEngine.position_key("washer", crew)].size() >= 2)
	for nm in ["Kozák", "Vojtek", "Koleno", "Majtán", "Zvak"]:
		assert_true(Constants.CANDIDATE_SURNAMES.has(nm))
	assert_true(Constants.CANDIDATE_SURNAMES.size() >= 20)
	var s5_v13 = copy_state(s5)
	s5_v13.version = 13
	var r5 = copy_state(s5_v13)
	assert_eq(FoundryEngine.duty(r5, "washer"), null)
	assert_eq(r5.hr.employees.size(), 2)
	print("OK new profession has three candidate lists and requested surnames are available")
	n += 1

	print(str(n) + " update 20 checks passed.")
	return true
