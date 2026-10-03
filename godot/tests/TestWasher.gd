class_name TestWasher
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

func setup() -> Dictionary:
	var s = Fixtures.fresh()
	s.goods["iron_pipe"] = 4
	s.money = 10000
	Fixtures.perform(s, { "type": "washer", "action": "configure", "product": "iron_pipe" })
	s.hr.rng = 202
	return s

func ok_washer(s: Dictionary, c: Dictionary) -> void:
	var cmd: Dictionary = { "type": "washer" }
	for k in c.keys():
		cmd[k] = c[k]
	var res = Fixtures.perform(s, cmd)
	assert_eq(res.ok, true, "Washer action failed: " + str(res.message))

func run_all() -> bool:
	n = 0
	
	# Test 1
	var s1 = setup()
	ok_washer(s1, { "action": "start" })
	assert_eq(s1.goods["iron_pipe"], 3)
	assert_eq(s1.money, 9994)
	assert_eq(FoundryEngine.reserved_output(s1), 1)
	assert_eq(FoundryEngine.wash_stage(s1), "loading")
	FoundryEngine.tick(s1, 3.0)
	assert_eq(FoundryEngine.wash_stage(s1), "washing")
	FoundryEngine.tick(s1, 7.0)
	assert_eq(FoundryEngine.wash_stage(s1), "ejecting")
	FoundryEngine.tick(s1, 3.99)
	assert_eq(s1.goods["clean_iron_pipe"], 0)
	FoundryEngine.tick(s1, 0.01)
	assert_eq(s1.goods["clean_iron_pipe"], 1)
	assert_eq(s1.washer.cleaned, 1)
	assert_eq(FoundryEngine.used(s1, "goods"), 4)
	FoundryEngine.tick(s1, 10.0)
	assert_eq(s1.goods["clean_iron_pipe"], 1)
	print("OK one pipe, one cost, three phases, one clean output at 14 seconds")
	n += 1

	# Test 2
	var s2 = setup()
	s2.goods["iron_pipe"] = 24
	ok_washer(s2, { "action": "start" })
	assert_eq(Fixtures.perform(s2, { "type": "trade", "item": "goods:ring", "side": "buy", "quantity": 1 }).ok, false)
	FoundryEngine.tick(s2, 14.0)
	assert_eq(FoundryEngine.used(s2, "goods"), 24)
	assert_eq(FoundryEngine.reserved_output(s2), 0)
	print("OK full warehouse converts in place and reserves output during cleaning")
	n += 1

	# Test 3
	for block in ["empty stock", "debt", "cash", "busy"]:
		var s3 = setup()
		if block == "empty stock":
			s3.goods["iron_pipe"] = 0
		if block == "debt":
			s3.payroll.debt = 1
		if block == "cash":
			s3.money = 5
		if block == "busy":
			ok_washer(s3, { "action": "start" })
		var before: String = JSON.stringify(s3)
		assert_eq(Fixtures.perform(s3, { "type": "washer", "action": "start" }).ok, false)
		assert_eq(JSON.stringify(s3), before)
	print("OK reserved stock, debts, cash and busy guards leave state intact")
	n += 1

	# Test 4
	var s4 = setup()
	ok_washer(s4, { "action": "start" })
	FoundryEngine.tick(s4, 6.0)
	var r = copy_state(s4)
	assert_eq(JSON.stringify(r.washer), JSON.stringify(s4.washer))
	FoundryEngine.tick(r, 8.0)
	assert_eq(r.goods["clean_iron_pipe"], 1)
	assert_eq(r.money, s4.money)
	var old = setup()
	old.version = 7
	old.erase("washer")
	old.goods.erase("clean_iron_pipe")
	old.goods.erase("clean_steel_pipe")
	var migrated = copy_state(old)
	assert_eq(migrated.version, 14)
	assert_eq(migrated.goods["iron_pipe"], 4)
	assert_eq(migrated.goods["clean_iron_pipe"], 0)
	assert_eq(migrated.washer.active, null)
	print("OK active save resumes without charging or duplicating output; v7 preserves stocks")
	n += 1

	# Test 5
	var s5 = setup()
	ok_washer(s5, { "action": "auto", "enabled": true })
	var a = copy_state(s5)
	var b = copy_state(s5)
	FoundryEngine.tick(a, 58.0)
	for i in range(3480):
		FoundryEngine.tick(b, 1.0 / 60.0)
	assert_eq(JSON.stringify(a.goods), JSON.stringify(b.goods))
	assert_eq(a.money, b.money)
	assert_eq(a.washer.cleaned, 4)
	assert_eq(a.washer.active, null)
	print("OK automatic cleaning agrees for large and small steps and stops when empty")
	n += 1

	# Test 6
	var s6 = setup()
	s6.goods["steel_pipe"] = 2
	ok_washer(s6, { "action": "configure", "product": "steel_pipe" })
	ok_washer(s6, { "action": "start" })
	FoundryEngine.tick(s6, 14.0)
	assert_eq(s6.goods["clean_steel_pipe"], 1)
	assert_eq(Fixtures.perform(s6, { "type": "trade", "item": "goods:clean_steel_pipe", "side": "sell", "quantity": 1 }).ok, true)
	assert_eq(s6.goods["clean_steel_pipe"], 0)
	s6.unlocked.append("steel_pipe")
	FoundryEngine.tick(s6, 121.0)
	var found_c: Variant = null
	for c in s6.contracts:
		if Constants.PRODUCTS[c.product].finished and c.status == "offer":
			found_c = c
			break
	assert_true(found_c != null, "Contract for finished product found")
	s6.goods[found_c.product] = found_c.quantity
	assert_eq(Fixtures.perform(s6, { "type": "contract", "id": found_c.id, "action": "accept" }).ok, true)
	assert_eq(Fixtures.perform(s6, { "type": "contract", "id": found_c.id, "action": "fulfill" }).ok, true)
	print("OK steel pipes clean, trade and fulfill clean-product contracts")
	n += 1

	# Test 7
	var s7 = setup()
	for prod in ["clean_ring", "clean_iron_pipe", "constructor"]:
		assert_eq(Fixtures.perform(s7, { "type": "washer", "action": "configure", "product": prod }).ok, false)
	assert_eq(Fixtures.perform(s7, { "type": "machine", "slot": 0, "action": "configure", "product": "clean_iron_pipe" }).ok, false)
	print("OK finished goods cannot become casting recipes or invalid washer programs")
	n += 1

	print(str(n) + " washer checks passed.")
	return true
