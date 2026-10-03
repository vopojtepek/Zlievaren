class_name TestUpdate19
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

func ok_cmd(s: Dictionary, c: Dictionary) -> void:
	var res = FoundryEngine.perform(s, c)
	assert_eq(res.ok, true, "Command failed: " + JSON.stringify(c) + " (" + str(res.get("message")) + ")")

func hire(s: Dictionary, role: String, crew: int = 0, slot: int = -1) -> Dictionary:
	var pos_key: String = FoundryEngine.position_key(role, crew, slot)
	var cand_id = s.hr.candidates[pos_key][0].id
	ok_cmd(s, { "type": "personnel", "action": "hire", "position": pos_key, "candidateId": cand_id })
	return FoundryEngine.assigned(s, pos_key)

func run_all() -> bool:
	n = 0

	# Test 1
	var s1 = Fixtures.fresh()
	s1.version = 12
	for i in range(s1.hr.employees.size()):
		s1.hr.employees[i].absence = 1.0 + float(i % 20)
	for list_c in s1.hr.candidates.values():
		for i in range(list_c.size()):
			list_c[i].absence = float(i + 1)
			list_c[i].salary = FoundryEngine.candidate_salary("operator", int(list_c[i].get("defect", 5)), list_c[i].absence / 2.0)
	var before1: Dictionary = JSON.parse_string(JSON.stringify(s1))
	var r1 = copy_state(s1)
	assert_eq(r1.version, 14)
	for i in range(r1.hr.employees.size()):
		assert_eq(r1.hr.employees[i].absence, before1.hr.employees[i].absence / 2.0)
		assert_eq(r1.hr.employees[i].salary, before1.hr.employees[i].salary)
	assert_eq(JSON.stringify(copy_state(r1).hr), JSON.stringify(r1.hr))
	assert_eq(JSON.stringify(r1.hr.attendance), JSON.stringify(s1.hr.attendance))
	var fresh_s = FoundryEngine.fresh()
	for list_c in fresh_s.hr.candidates.values():
		for c in list_c:
			assert_true(float(c.absence) >= 0.5 and float(c.absence) <= 10.0)
	print("OK absence percentages halve exactly once, without changing existing contracts or salaries")
	n += 1

	# Test 2
	var s2 = Fixtures.fresh()
	var e2 = hire(s2, "operator", 0, 0)
	e2.defect = 7
	for other in s2.hr.employees:
		if other.id != e2.id:
			other.defect = 15
	for pair in [[1, 0.37], [2, 0.27], [3, 0.17]]:
		var lvl: int = pair[0]
		var exp_risk: float = pair[1]
		var m_chk: Dictionary = s2.machines[0].duplicate(true)
		m_chk.level = lvl
		assert_true(abs(FoundryEngine.total_failure_risk(s2, m_chk, 0) - exp_risk) < 1e-8)
	s2.rng = 0
	for mat in s2.incoming.keys():
		ok_cmd(s2, { "type": "store", "material": mat, "quantity": s2.incoming[mat] })
	assert_eq(FoundryEngine.act_machine(s2, 0, "cast").ok, true)
	assert_eq(s2.machines[0].batchRisk, 0.37)
	assert_eq(copy_state(s2).machines[0].batchRisk, 0.37)
	print("OK only assigned on-duty machine operator adds risk, by direct percentage addition")
	n += 1

	# Test 3
	var s3 = FoundryEngine.fresh()
	s3.hr.rng = 202
	FoundryEngine.tick(s3, 180.0)
	for l in s3.ledger:
		for nm in ["Matino", "Miči", "Maslo"]:
			assert_true(not l.text.contains(nm))
	var e3 = hire(s3, "ladle", 1)
	e3.name = "Skutočný pracovník"
	e3.absence = 0.5
	s3.hr.rng = 202
	FoundryEngine.tick(s3, 60.0)
	var found_skutocny: bool = false
	for l in s3.ledger:
		if l.text.contains("v práci: Skutočný pracovník"):
			found_skutocny = true
			break
	assert_true(found_skutocny)
	print("OK shift ledger never names unstaffed legacy workers and uses actual recruited names")
	n += 1

	# Test 4
	var s4 = FoundryEngine.fresh()
	hire(s4, "warehouse")
	s4.incoming = { "iron": 0, "zinc": 0, "steel": 1, "copper": 1, "tin": 1 }
	assert_eq(FoundryEngine.bin_capacity(s4, "iron"), 60)
	assert_eq(FoundryEngine.bin_capacity(s4, "zinc"), 40)
	for id in ["steel", "copper", "tin"]:
		assert_eq(FoundryEngine.bin_capacity(s4, id), 0)
		assert_eq(FoundryEngine.perform(s4, { "type": "store", "material": id, "quantity": 1 }).ok, false)
		s4.money = Constants.BIN_UNLOCK[id] - 1
		assert_eq(FoundryEngine.perform(s4, { "type": "expandBin", "material": id }).ok, false)
		s4.money = Constants.BIN_UNLOCK[id]
		ok_cmd(s4, { "type": "expandBin", "material": id })
		assert_eq(s4.money, 0)
		assert_eq(s4.bins[id], 0)
		assert_eq(FoundryEngine.bin_capacity(s4, id), Constants.BIN_BASE[id])
		ok_cmd(s4, { "type": "store", "material": id, "quantity": 1 })
		s4.money = 170
		ok_cmd(s4, { "type": "expandBin", "material": id })
		assert_eq(s4.money, 50)
		assert_eq(FoundryEngine.bin_capacity(s4, id), 2 * Constants.BIN_BASE[id])
	assert_eq(JSON.stringify(copy_state(s4).binUnlocked), JSON.stringify(s4.binUnlocked))
	var old4 = FoundryEngine.fresh()
	old4.version = 12
	var mig4 = copy_state(old4)
	for b_val in mig4.binUnlocked.values():
		assert_true(b_val == true)
	print("OK locked bins refuse material and unlock for their exact price; upgrades are separate")
	n += 1

	# Test 5
	var s5 = Fixtures.fresh()
	s5.version = 12
	s5.goods["ring"] = 3
	s5.goods["bronze_bushing"] = 2
	s5.limits = [{ "id": 1, "product": "ring", "quantity": 2, "minPrice": 999, "created": s5.clock }]
	s5.contracts = [
		{ "id": "old-ring", "product": "ring", "quantity": 1, "payout": 100, "buyer": Constants.COMPANIES[0], "status": "active", "deadline": s5.clock + 3.0 },
		{ "id": "old-bronze", "product": "bronze_bushing", "quantity": 2, "payout": 200, "buyer": Constants.COMPANIES[1], "status": "offer", "offerDeadline": s5.clock + 60.0 }
	]
	var r5 = copy_state(s5)
	assert_eq(r5.goods["ring"], 3)
	assert_eq(r5.goods["bronze_bushing"], 2)
	assert_eq(r5.limits.size(), 0)
	var prod_list = r5.contracts.map(func(c): return c.product)
	assert_eq(JSON.stringify(prod_list), JSON.stringify(["clean_ring", "clean_bronze_bushing"]))
	assert_eq(r5.contracts[0].payout, 100)
	assert_eq(r5.contracts[0].deadline, r5.clock + 135.0)
	assert_eq(JSON.stringify(copy_state(r5).contracts), JSON.stringify(r5.contracts))
	print("OK old ring and bushing contracts migrate once; stock is preserved and raw sale orders release")
	n += 1

	# Test 6
	for id in ["ring", "bronze_bushing"]:
		var s6 = Fixtures.fresh()
		s6.money = 10000
		s6.goods[id] = 2
		hire(s6, "washer")
		ok_cmd(s6, { "type": "washer", "action": "configure", "product": id })
		ok_cmd(s6, { "type": "washer", "action": "start" })
		FoundryEngine.tick(s6, 5.0)
		var r6 = copy_state(s6)
		FoundryEngine.tick(r6, 9.0)
		var clean: String = Constants.WASH.outputs[id]
		assert_eq(r6.goods[id], 1)
		assert_eq(r6.goods[clean], 1)
		assert_eq(r6.money, 9994)
		assert_eq(FoundryEngine.perform(r6, { "type": "trade", "item": "goods:" + id, "side": "sell", "quantity": 1 }).ok, false)
		r6.contracts = [{ "id": "clean", "product": clean, "quantity": 1, "payout": 100, "buyer": Constants.COMPANIES[0], "status": "offer", "offerDeadline": r6.clock + 60.0 }]
		ok_cmd(r6, { "type": "contract", "id": "clean", "action": "accept" })
		ok_cmd(r6, { "type": "contract", "id": "clean", "action": "fulfill" })
		assert_eq(r6.goods[clean], 0)
		assert_eq(r6.goods[id], 1)
	print("OK new washable products finish through reload, preserve counts and fulfil orders only after cleaning")
	n += 1

	# Test 7
	for id in Constants.PRODUCTS.keys():
		var p = Constants.PRODUCTS[id]
		if not p.finished:
			assert_eq(p.temp, 1700)
			var m = { "product": id, "level": 1, "state": "working", "elapsed": Constants.FLOW.pourEnd }
			assert_eq(FoundryEngine.temperature(m), 1700)
			m.elapsed += 1.0
			assert_true(FoundryEngine.temperature(m) < 1700)
	print("OK all melt programs reach 1700 at pouring end and cool afterwards")
	n += 1

	print(str(n) + " update 19 checks passed.")
	return true
