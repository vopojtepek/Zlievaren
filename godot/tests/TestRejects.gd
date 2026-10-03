class_name TestRejects
extends RefCounted

var passed: int = 0

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

func setup(seed_val: int = 2000) -> Dictionary:
	var s: Dictionary = Fixtures.fresh()
	s.rng = seed_val
	s.money = 100000
	for mat in s.incoming.keys():
		Fixtures.perform(s, { "type": "store", "material": mat, "quantity": s.incoming[mat] })
	for crew in range(3):
		Fixtures.perform(s, { "type": "employment", "action": "hire", "slot": 0, "crew": crew })
	return s

func run_all() -> bool:
	passed = 0

	# Test 1
	var s1 = setup()
	for c in s1.contracts:
		var exp_p: int = int(round(round(float(Constants.PRODUCTS[c.product].base) * 1.3) * float(c.quantity) * 0.75))
		assert_eq(c.payout, exp_p)
	Fixtures.perform(s1, { "type": "unlock", "product": "steel_pipe" })
	var c_last: Dictionary = s1.contracts[s1.contracts.size() - 1]
	var exp_last: int = int(round(round(float(Constants.PRODUCTS["clean_steel_pipe"].base) * 1.3) * 2.0 * 0.75))
	assert_eq(c_last.payout, exp_last)
	print("OK all new contracts and recipe-unlock offers retain exactly 75% of previous cash reward")
	passed += 1

	# Test 2
	var s2 = setup()
	s2.version = 6
	s2.raw["coke"] = s2.raw["zinc"]
	s2.raw.erase("zinc")
	s2.incoming["coke"] = 9
	s2.incoming.erase("zinc")
	s2.bins["coke"] = 3
	s2.bins.erase("zinc")
	for c in s2.contracts:
		c.payout = 400
	s2.contracts[0].status = "active"
	s2.contracts[0].deadline = s2.clock + 100.0
	s2.contracts[1].status = "done"
	var r2 = clone(s2)
	assert_eq(r2.raw["zinc"], 16)
	assert_eq(r2.incoming["zinc"], 9)
	assert_eq(r2.bins["zinc"], 3)
	assert_eq(FoundryEngine.bin_capacity(r2, "zinc"), 160)
	assert_true(not r2.raw.has("coke"))
	assert_eq(r2.contracts[0].payout, 300)
	assert_eq(r2.contracts[1].payout, 400)
	assert_eq(r2.contracts[2].payout, 300)
	assert_eq(JSON.stringify(clone(r2).contracts), JSON.stringify(r2.contracts))
	assert_eq(r2.money, s2.money)
	assert_true(FoundryEngine.quote(r2, "raw:coke") == null)
	assert_true(FoundryEngine.quote(r2, "raw:zinc").ask > 0)
	print("OK old stocks, receiving dock and upgraded coke bin migrate to zinc once")
	passed += 1

	# Test 3
	for prod in ["iron_pipe", "steel_pipe"]:
		for lvl in [1, 2, 3]:
			var s3 = setup()
			var m = s3.machines[0]
			s3.unlocked.append(prod)
			m.product = prod
			m.level = lvl
			var raw_before = s3.raw.duplicate(true)
			assert_eq(FoundryEngine.act_machine(s3, 0, "cast").ok, true)
			assert_eq(m.reject, true)
			FoundryEngine.tick(s3, Constants.FLOW.pourEnd)
			assert_eq(m.state, "failed")
			assert_eq(s3.scrapped, 1)
			assert_eq(s3.made, 0)
			assert_eq(s3.sold, 0)
			assert_eq(FoundryEngine.used(s3, "goods"), 0)
			assert_eq(FoundryEngine.reserved_output(s3), 0)
			assert_eq(FoundryEngine.act_machine(s3, 0, "sell").ok, false)
			assert_eq(FoundryEngine.act_machine(s3, 0, "collect").ok, false)
			assert_eq(FoundryEngine.act_machine(s3, 0, "cast").ok, false)
			for id in Constants.PRODUCTS[prod].recipe.keys():
				assert_eq(s3.raw[id], raw_before[id] - Constants.PRODUCTS[prod].recipe[id])
			FoundryEngine.tick(s3, 3.99)
			assert_eq(m.state, "failed")
			FoundryEngine.tick(s3, 0.01)
			assert_eq(m.state, "idle")
			assert_eq(s3.scrapped, 1)
	print("OK rejection consumes ingredients once but creates no goods, sales or milestones")
	passed += 1

	# Test 4
	var s4 = setup(1000)
	FoundryEngine.act_machine(s4, 0, "cast")
	assert_eq(s4.machines[0].reject, false)
	FoundryEngine.tick(s4, 28.0)
	assert_eq(s4.machines[0].state, "unloading")
	assert_eq(s4.made, 1)
	assert_eq(s4.scrapped, 0)
	for prod in ["ring", "bronze_bushing"]:
		var t = setup()
		t.unlocked.append(prod)
		t.machines[0].product = prod
		var seed_saved = t.rng
		FoundryEngine.act_machine(t, 0, "cast")
		assert_eq(FoundryEngine.failure_risk(t.machines[0]), 0.0)
		assert_eq(t.rng, seed_saved)
		FoundryEngine.tick(t, FoundryEngine.duration(1, prod))
		assert_eq(t.made, 1)
		assert_eq(t.scrapped, 0)
	print("OK success creates exactly one finished pipe; other products do not roll pipe defects")
	passed += 1

	# Test 5
	for lvl in [1, 2, 3]:
		var s5 = setup(912345)
		var m5 = s5.machines[0]
		m5.level = lvl
		s5.raw["iron"] = 100000
		s5.raw["zinc"] = 20000
		var rejects: int = 0
		var expected: float = [0.3, 0.2, 0.1][lvl - 1]
		assert_eq(FoundryEngine.failure_risk(m5), expected)
		for i in range(10000):
			assert_eq(FoundryEngine.act_machine(s5, 0, "cast").ok, true)
			if m5.reject:
				rejects += 1
			m5.state = "idle"
			s5.queue = []
		var diff = abs((float(rejects) / 10000.0) - (expected + 0.01))
		assert_true(diff < 0.015, "Observed rate " + str(float(rejects) / 10000.0))
	print("OK exact risk levels and deterministic long-run reject rates")
	passed += 1

	# Test 6
	var s6 = setup()
	FoundryEngine.act_machine(s6, 0, "cast")
	FoundryEngine.tick(s6, 6.0)
	var r6 = clone(s6)
	assert_eq(r6.machines[0].reject, true)
	assert_eq(r6.rng, s6.rng)
	FoundryEngine.tick(r6, 5.5)
	assert_eq(r6.machines[0].state, "failed")
	var again = clone(r6)
	var age = again.machines[0].failedElapsed
	FoundryEngine.tick(again, 0.0)
	assert_eq(again.machines[0].failedElapsed, age)
	assert_eq(again.scrapped, 1)
	FoundryEngine.tick(again, 4.0 - age)
	assert_eq(again.machines[0].state, "idle")
	assert_eq(again.scrapped, 1)
	assert_eq(FoundryEngine.used(again, "goods"), 0)
	print("OK reload cannot reroll a queued batch and preserves an in-progress burst")
	passed += 1

	# Test 7
	var s7 = setup()
	FoundryEngine.act_machine(s7, 1, "buy")
	for crew in range(3):
		Fixtures.perform(s7, { "type": "employment", "action": "hire", "slot": 1, "crew": crew })
	s7.machines[0].auto = true
	FoundryEngine.act_machine(s7, 0, "cast")
	FoundryEngine.act_machine(s7, 1, "cast")
	FoundryEngine.tick(s7, 14.2)
	assert_eq(s7.machines[0].state, "working")
	assert_eq(s7.delivery.slot, 1)
	assert_eq(s7.queue[0], 0)
	assert_eq(s7.scrapped, 1)
	assert_eq(s7.raw["iron"], 18)
	assert_eq(s7.raw["zinc"], 13)
	print("OK rejects release the shared ladle and automatic production resumes safely")
	passed += 1

	# Test 8
	var s8 = setup()
	s8.raw["iron"] = 300
	s8.raw["zinc"] = 100
	s8.machines[0].auto = true
	FoundryEngine.act_machine(s8, 1, "buy")
	for crew in range(3):
		Fixtures.perform(s8, { "type": "employment", "action": "hire", "slot": 1, "crew": crew })
	s8.machines[1].auto = true
	var a8 = clone(s8)
	var b8 = clone(s8)
	FoundryEngine.tick(a8, 180.0)
	for i in range(10800):
		FoundryEngine.tick(b8, 1.0 / 60.0)
	assert_eq(a8.scrapped, b8.scrapped)
	assert_true(a8.scrapped > 0)
	assert_eq(a8.made, b8.made)
	assert_eq(a8.rng, b8.rng)
	assert_eq(JSON.stringify(a8.raw), JSON.stringify(b8.raw))
	assert_eq(JSON.stringify(a8.goods), JSON.stringify(b8.goods))
	assert_eq(a8.money, b8.money)
	print("OK large and frame-sized steps agree with rejects and serial production")
	passed += 1

	print(str(passed) + " rejection and migration checks passed.")
	return true
