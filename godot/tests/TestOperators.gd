class_name TestOperators
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

func clone(s: Dictionary) -> Dictionary:
	return FoundryEngine.restore(JSON.stringify(s))

func ok_cmd(s: Dictionary, c: Dictionary) -> void:
	var res = Fixtures.perform(s, c)
	assert_eq(res.ok, true, "Command failed: " + JSON.stringify(c) + " (" + str(res.get("message")) + ")")

func hire(s: Dictionary, slot: int = 0, crew: int = 0) -> void:
	ok_cmd(s, { "type": "employment", "action": "hire", "slot": slot, "crew": crew })

func setup() -> Dictionary:
	var s: Dictionary = Fixtures.fresh()
	s.money = 10000
	s.rng = 1000
	for mat in s.incoming.keys():
		if s.incoming[mat] > 0:
			ok_cmd(s, { "type": "store", "material": mat, "quantity": s.incoming[mat] })
	return s

func run_all() -> bool:
	n = 0

	# Test 1
	var s1 = setup()
	ok_cmd(s1, { "type": "machine", "slot": 1, "action": "buy" })
	var raw1 = s1.raw.duplicate(true)
	assert_true(not FoundryEngine.can_cast(s1, 0).is_empty())
	hire(s1, 1, 0)
	hire(s1, 0, 1)
	assert_true(not FoundryEngine.can_cast(s1, 0).is_empty())
	assert_eq(FoundryEngine.act_machine(s1, 0, "cast").ok, false)
	assert_eq(JSON.stringify(s1.raw), JSON.stringify(raw1))
	hire(s1)
	assert_eq(FoundryEngine.can_cast(s1, 0), "")
	assert_eq(FoundryEngine.can_cast(s1, 1), "")
	assert_eq(Fixtures.perform(s1, { "type": "employment", "action": "hire", "slot": 2, "crew": 0 }).ok, false)
	assert_eq(Fixtures.perform(s1, { "type": "employment", "action": "hire", "slot": 0, "crew": 3 }).ok, false)
	print("OK machine purchase needs no staff; only its own on-duty hire unlocks production")
	n += 1

	# Test 2
	var s2 = setup()
	FoundryEngine.tick(s2, 30.0)
	var cash2 = s2.money
	hire(s2)
	assert_eq(s2.money, cash2)
	FoundryEngine.tick(s2, 15.0)
	assert_eq(int(round(s2.payroll.operatorAccrued[0])), 4)
	ok_cmd(s2, { "type": "employment", "action": "dismiss", "slot": 0, "crew": 0 })
	var r2 = clone(s2)
	FoundryEngine.tick(r2, FoundryEngine.next_pay(r2) - r2.clock)
	assert_eq(r2.payroll.history[0].due, 1500)
	assert_eq(r2.payroll.history[0].operators[0].name, "Boris")
	assert_eq(int(round(r2.payroll.history[0].operators[0].amount)), 4)
	assert_eq(r2.money, cash2 - 1500)
	print("OK hiring is free; partial wages persist on dismissal and reload")
	n += 1

	# Test 3
	var s3 = setup()
	for crew in range(3):
		hire(s3, 0, crew)
	assert_eq(FoundryEngine.shift_wages(2, s3), 120.0)
	FoundryEngine.tick(s3, 150.0)
	var r3 = clone(s3)
	assert_eq(JSON.stringify(r3.operators), JSON.stringify(s3.operators))
	assert_eq(JSON.stringify(r3.payroll), JSON.stringify(s3.payroll))
	FoundryEngine.tick(r3, FoundryEngine.next_pay(r3) - r3.clock)
	assert_eq(r3.payroll.paid, 1870)
	var op_rounded: Array = r3.payroll.history[0].operators.map(func(o): return int(round(o.amount)))
	assert_eq(JSON.stringify(op_rounded), JSON.stringify([112, 112, 150]))
	FoundryEngine.tick(r3, Constants.WEEK)
	assert_eq(r3.payroll.history[0].due, 1960)
	print("OK three hired shifts add 16 + 16 + 24 wages per day, exactly once")
	n += 1

	# Test 4
	var s4 = setup()
	hire(s4)
	ok_cmd(s4, { "type": "machine", "slot": 0, "action": "cast" })
	assert_eq(Fixtures.perform(s4, { "type": "employment", "action": "dismiss", "slot": 0, "crew": 0 }).ok, false)
	FoundryEngine.tick(s4, 29.5)
	assert_eq(s4.machines[0].state, "unloading")
	assert_eq(s4.goods["iron_pipe"], 0)
	assert_eq(FoundryEngine.reserved_output(s4), 1)
	assert_eq(Fixtures.perform(s4, { "type": "employment", "action": "dismiss", "slot": 0, "crew": 0 }).ok, false)
	var r4 = clone(s4)
	FoundryEngine.tick(r4, 0.0)
	assert_true(abs(r4.machines[0].unloadElapsed - 1.5) < 1e-8)
	FoundryEngine.tick(r4, 2.5)
	assert_eq(r4.goods["iron_pipe"], 1)
	assert_eq(r4.pallets[0]["iron_pipe"], 1)
	assert_eq(FoundryEngine.used(r4, "goods"), 1)
	assert_eq(FoundryEngine.reserved_output(r4), 0)
	FoundryEngine.tick(r4, 1.0)
	assert_eq(r4.goods["iron_pipe"], 1)
	print("OK unloading reserves capacity, survives save and deposits exactly one item on pallet")
	n += 1

	# Test 5
	var s5 = setup()
	s5.clock = 100.0
	hire(s5)
	ok_cmd(s5, { "type": "machine", "slot": 0, "action": "cast" })
	FoundryEngine.tick(s5, 28.0)
	assert_eq(FoundryEngine.shift(s5), 1)
	assert_eq(s5.machines[0].state, "ready")
	assert_eq(s5.goods["iron_pipe"], 0)
	assert_eq(FoundryEngine.act_machine(s5, 0, "collect").ok, false)
	hire(s5, 0, 1)
	FoundryEngine.tick(s5, 4.0)
	assert_eq(s5.goods["iron_pipe"], 1)
	assert_eq(s5.pallets[0]["iron_pipe"], 1)
	ok_cmd(s5, { "type": "employment", "action": "dismiss", "slot": 0, "crew": 1 })
	assert_true(not FoundryEngine.can_cast(s5, 0).is_empty())
	print("OK shift without replacement safely finishes batch, waits to unload and cannot restart")
	n += 1

	# Test 6
	for id in Constants.WASH.outputs.keys():
		var s6 = setup()
		s6.goods[id] = 2
		s6.pallets[0][id] = 2
		var cash6 = s6.money
		assert_eq(Fixtures.perform(s6, { "type": "trade", "item": "goods:" + id, "side": "sell", "quantity": 1 }).ok, false)
		assert_eq(Fixtures.perform(s6, { "type": "limit", "product": id, "quantity": 1, "minPrice": 1 }).ok, false)
		assert_eq(FoundryEngine.act_machine(s6, 0, "sell").ok, false)
		s6.contracts[0].product = id
		assert_eq(Fixtures.perform(s6, { "type": "contract", "id": s6.contracts[0].id, "action": "accept" }).ok, false)
		assert_eq(s6.money, cash6)
		ok_cmd(s6, { "type": "washer", "action": "configure", "product": id })
		ok_cmd(s6, { "type": "washer", "action": "start" })
		assert_eq(s6.goods[id], 1)
		assert_eq(s6.pallets[0][id], 1)
		FoundryEngine.tick(s6, 14.0)
		ok_cmd(s6, { "type": "trade", "item": "goods:" + Constants.WASH.outputs[id], "side": "sell", "quantity": 1 })
		assert_eq(s6.sold, 1)
	print("OK both pipe types must be cleaned; no direct, market, limit or contract bypass")
	n += 1

	# Test 7
	var s7 = setup()
	for id in Constants.PRODUCTS.keys():
		var before = JSON.stringify(s7)
		assert_eq(Fixtures.perform(s7, { "type": "trade", "item": "goods:" + id, "side": "buy", "quantity": 1 }).ok, false)
		assert_eq(JSON.stringify(s7), before)
	ok_cmd(s7, { "type": "trade", "item": "raw:iron", "side": "buy", "quantity": 1 })
	ok_cmd(s7, { "type": "trade", "item": "raw:iron", "side": "sell", "quantity": 1 })
	print("OK every finished/intermediate product refuses purchase; raw trading remains available")
	n += 1

	# Test 8
	for mode in ["trade", "limit", "contract"]:
		var s8 = setup()
		s8.goods["clean_ring"] = 3
		s8.pallets[0]["clean_ring"] = 2
		s8.pallets[1]["clean_ring"] = 1
		if mode == "trade":
			ok_cmd(s8, { "type": mode, "item": "goods:clean_ring", "side": "sell", "quantity": 2 })
		elif mode == "limit":
			ok_cmd(s8, { "type": mode, "product": "clean_ring", "quantity": 2, "minPrice": 1 })
			FoundryEngine.tick(s8, 15.0)
		elif mode == "contract":
			var c = s8.contracts[0]
			c.product = "clean_ring"
			c.quantity = 2
			ok_cmd(s8, { "type": mode, "id": c.id, "action": "accept" })
			ok_cmd(s8, { "type": mode, "id": c.id, "action": "fulfill" })
		assert_eq(s8.goods["clean_ring"], 1)
		var total_pallets: int = 0
		for p in s8.pallets:
			total_pallets += p.get("clean_ring", 0)
		assert_eq(total_pallets, 1)
	print("OK pallet stock is consumed once by direct, limit and contract sales")
	n += 1

	# Test 9
	var s9 = setup()
	s9.version = 9
	s9.goods["iron_pipe"] = 4
	s9.limits = [{ "id": 1, "product": "iron_pipe", "quantity": 3, "minPrice": 999, "created": s9.clock }]
	var c9 = s9.contracts[0]
	c9.product = "iron_pipe"
	c9.status = "active"
	c9.deadline = s9.clock + 1.0
	var payout9 = c9.payout
	hire(s9)
	FoundryEngine.act_machine(s9, 0, "cast")
	FoundryEngine.tick(s9, 0.5)
	var r9 = clone(s9)
	assert_eq(r9.money, s9.money)
	assert_eq(JSON.stringify(r9.goods), JSON.stringify(s9.goods))
	assert_eq(r9.machines[0].state, "working")
	assert_eq(FoundryEngine.operator_count(r9, 0), 0)
	assert_eq(r9.limits.size(), 0)
	assert_eq(r9.contracts[0].product, "clean_iron_pipe")
	assert_eq(r9.contracts[0].payout, payout9)
	assert_eq(r9.contracts[0].deadline, r9.clock + 135.0)
	FoundryEngine.tick(r9, 10.0)
	assert_eq(clone(r9).contracts[0].deadline, s9.clock + 135.0)
	print("OK v9 migration preserves inventory, cash and work; cancels raw limits and extends converted active contracts only once")
	n += 1

	# Test 10
	var s10 = setup()
	var unl_prods: Array = []
	for id in Constants.PRODUCTS.keys():
		if not Constants.PRODUCTS[id].finished:
			unl_prods.append(id)
	s10.unlocked = unl_prods
	for i in range(8):
		FoundryEngine.tick(s10, 180.0)
		for c in s10.contracts:
			assert_true(FoundryEngine.saleable(c.product))
	print("OK new offers never request unwashed pipes")
	n += 1

	print(str(n) + " staffing and sales checks passed.")
	return true
