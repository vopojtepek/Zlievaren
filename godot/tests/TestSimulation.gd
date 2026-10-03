class_name TestSimulation
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

func assert_near(a: float, b: float, eps: float = 1e-5, msg: String = "") -> void:
	if abs(a - b) >= eps:
		printerr("FAIL: ", msg, " | ", a, " != ", b)
		assert(false)

func clone(s: Dictionary) -> Dictionary:
	return s.duplicate(true)

func do_it(s: Dictionary, c: Dictionary) -> Dictionary:
	var r = Fixtures.perform(s, c)
	assert_true(r.ok, JSON.stringify(c) + " failed: " + r.get("message", ""))
	return r

func hire(s: Dictionary, slot: int = 0) -> Dictionary:
	for crew in range(3):
		do_it(s, { "type": "employment", "action": "hire", "slot": slot, "crew": crew })
	return s

func stocked() -> Dictionary:
	var s = Fixtures.fresh()
	s.rng = 1000
	for mat in s.incoming.keys():
		var quantity = s.incoming[mat]
		if quantity > 0:
			Fixtures.perform(s, { "type": "store", "material": mat, "quantity": quantity })
	return s

func staffed() -> Dictionary:
	return hire(stocked())

func run_all() -> bool:
	n = 0

	# Test 1
	var s1 = stocked()
	assert_eq(FoundryEngine.clock_text(s1), "06:00")
	FoundryEngine.tick(s1, 60.0)
	assert_eq(FoundryEngine.clock_text(s1), "14:00")
	assert_eq(FoundryEngine.shift(s1), 1)
	FoundryEngine.tick(s1, 60.0)
	assert_eq(FoundryEngine.clock_text(s1), "22:00")
	assert_eq(FoundryEngine.shift(s1), 2)
	FoundryEngine.tick(s1, 60.0)
	assert_eq(FoundryEngine.day(s1), 2)
	assert_eq(FoundryEngine.clock_text(s1), "06:00")
	assert_eq(s1.shiftChanges, 3)
	print("OK 180 seconds per day; exact 06/14/22 shifts")
	n += 1

	# Test 2
	var s2 = staffed()
	var money2 = s2.money
	do_it(s2, { "type": "machine", "slot": 0, "action": "cast" })
	assert_eq(s2.raw.iron, 30)
	assert_eq(s2.raw.zinc, 15)
	assert_eq(FoundryEngine.reserved_output(s2), 1)
	FoundryEngine.tick(s2, 28.0)
	assert_eq(s2.machines[0].state, "unloading")
	assert_eq(s2.made, 1)
	assert_eq(FoundryEngine.temperature(s2.machines[0]), 180)
	FoundryEngine.tick(s2, 4.0)
	assert_eq(s2.goods.iron_pipe, 1)
	do_it(s2, { "type": "washer", "action": "start" })
	FoundryEngine.tick(s2, 14.0)
	var bid2 = FoundryEngine.quote(s2, "goods:clean_iron_pipe").bid
	do_it(s2, { "type": "trade", "item": "goods:clean_iron_pipe", "side": "sell", "quantity": 1 })
	assert_eq(s2.goods.clean_iron_pipe, 0)
	assert_eq(s2.money, money2 + bid2 - 6)
	assert_eq(s2.sold, 1)
	assert_eq(Fixtures.perform(s2, { "type": "trade", "item": "goods:iron_pipe", "side": "sell", "quantity": 1 }).ok, false)
	print("OK material -> work in progress -> inventory -> sale conservation")
	n += 1

	# Test 3
	for id3 in Constants.PRODUCTS.keys():
		var p3 = Constants.PRODUCTS[id3]
		if p3.get("finished") == true:
			continue
		var s3 = staffed()
		s3.unlocked.append(id3)
		do_it(s3, { "type": "machine", "slot": 0, "action": "configure", "product": id3 })
		var before3 = clone(s3.raw)
		do_it(s3, { "type": "machine", "slot": 0, "action": "cast" })
		for raw_id in p3.recipe.keys():
			var req_n = p3.recipe[raw_id]
			assert_eq(s3.raw[raw_id], before3[raw_id] - req_n)
		FoundryEngine.tick(s3, 13.0)
		assert_eq(FoundryEngine.stage(s3.machines[0]), "cooling")
		var hot3 = FoundryEngine.temperature(s3.machines[0])
		FoundryEngine.tick(s3, 3.0)
		assert_true(FoundryEngine.temperature(s3.machines[0]) < hot3)
		FoundryEngine.tick(s3, float(p3.seconds) - 16.0)
		FoundryEngine.tick(s3, 4.0)
		assert_eq(s3.goods[id3], 1)
	print("OK all four products complete with their own recipes and cooling")
	n += 1

	# Test 4
	var s4 = staffed()
	s4.money = 2000
	do_it(s4, { "type": "machine", "slot": 1, "action": "buy" })
	hire(s4, 1)
	s4.clock = 100.0
	do_it(s4, { "type": "machine", "slot": 0, "action": "cast" })
	do_it(s4, { "type": "machine", "slot": 1, "action": "cast" })
	FoundryEngine.tick(s4, 6.0)
	assert_eq(FoundryEngine.shift(s4), 1)
	assert_eq(s4.delivery.crew, 0)
	assert_eq(FoundryEngine.stage(s4.machines[1]), "waiting")
	FoundryEngine.tick(s4, 8.0)
	assert_eq(s4.delivery.slot, 1)
	assert_eq(s4.delivery.crew, 1)
	FoundryEngine.tick(s4, 40.0)
	assert_true(s4.machines[0].state == "idle" and s4.machines[1].state == "idle")
	print("OK single ladle queue and shift handover preserve current operator")
	n += 1

	# Test 5
	var s5 = staffed()
	s5.raw.iron = 6
	s5.raw.zinc = 1
	do_it(s5, { "type": "machine", "slot": 0, "action": "auto", "enabled": true })
	FoundryEngine.tick(s5, 60.0)
	assert_eq(s5.goods.iron_pipe, 1)
	assert_eq(s5.machines[0].state, "idle")
	do_it(s5, { "type": "trade", "item": "raw:iron", "side": "buy", "quantity": 6 })
	do_it(s5, { "type": "trade", "item": "raw:zinc", "side": "buy", "quantity": 1 })
	do_it(s5, { "type": "store", "material": "iron", "quantity": 6 })
	do_it(s5, { "type": "store", "material": "zinc", "quantity": 1 })
	FoundryEngine.tick(s5, 32.0)
	assert_eq(s5.goods.iron_pipe, 2)
	assert_eq(s5.raw.iron, 0)
	print("OK series stops on missing ingredients and resumes after purchase")
	n += 1

	# Test 6
	var s6 = staffed()
	s6.unlocked.append("ring")
	s6.machines[0].product = "ring"
	s6.goods.ring = 23
	do_it(s6, { "type": "machine", "slot": 0, "action": "auto", "enabled": true })
	FoundryEngine.tick(s6, 1.0)
	assert_eq(Fixtures.perform(s6, { "type": "trade", "item": "goods:ring", "side": "buy", "quantity": 1 }).ok, false)
	FoundryEngine.tick(s6, 40.0)
	assert_eq(s6.goods.ring, 24)
	assert_eq(s6.machines[0].state, "idle")
	do_it(s6, { "type": "washer", "action": "configure", "product": "ring" })
	do_it(s6, { "type": "washer", "action": "start" })
	FoundryEngine.tick(s6, 14.0)
	do_it(s6, { "type": "trade", "item": "goods:clean_ring", "side": "sell", "quantity": 1 })
	FoundryEngine.tick(s6, 28.0)
	assert_eq(s6.goods.ring, 24)
	assert_eq(s6.machines[0].state, "idle")
	print("OK capacity reserves output; full warehouse halts and resumes series")
	n += 1

	# Test 7
	var s7 = stocked()
	s7.goods.clean_iron_pipe = 4
	do_it(s7, { "type": "limit", "product": "clean_iron_pipe", "quantity": 3, "minPrice": 1 })
	assert_eq(FoundryEngine.available(s7, "clean_iron_pipe"), 1)
	assert_eq(Fixtures.perform(s7, { "type": "trade", "item": "goods:clean_iron_pipe", "side": "sell", "quantity": 2 }).ok, false)
	FoundryEngine.tick(s7, 15.0)
	assert_eq(s7.limits.size(), 0)
	assert_eq(s7.goods.clean_iron_pipe, 1)
	assert_eq(s7.sold, 3)
	FoundryEngine.tick(s7, 30.0)
	assert_eq(s7.sold, 3)
	print("OK limit reservations cannot be sold twice; execute only once")
	n += 1

	# Test 8
	var s8 = stocked()
	var c8 = s8.contracts[0]
	s8.goods[c8.product] = c8.quantity
	do_it(s8, { "type": "contract", "id": c8.id, "action": "accept" })
	do_it(s8, { "type": "limit", "product": c8.product, "quantity": 1, "minPrice": 9999 })
	assert_eq(Fixtures.perform(s8, { "type": "contract", "id": c8.id, "action": "fulfill" }).ok, false)
	do_it(s8, { "type": "cancelLimit", "id": s8.limits[0].id })
	var money8 = s8.money
	do_it(s8, { "type": "contract", "id": c8.id, "action": "fulfill" })
	assert_eq(s8.money, money8 + c8.payout)
	assert_eq(s8.goods[c8.product], 0)
	assert_eq(s8.reputation, 2)
	assert_eq(Fixtures.perform(s8, { "type": "contract", "id": c8.id, "action": "fulfill" }).ok, false)
	print("OK cancel releases stock; contracts use unreserved goods and pay once")
	n += 1

	# Test 9
	var s9 = stocked()
	s9.reputation = 2
	var c9 = s9.contracts[0]
	do_it(s9, { "type": "contract", "id": c9.id, "action": "accept" })
	FoundryEngine.tick(s9, 135.0)
	assert_eq(c9.status, "expired")
	assert_eq(s9.reputation, 1)
	assert_eq(FoundryEngine.day(s9), 2)
	var has_d2 = false
	for x in s9.contracts:
		if x.id.begins_with("D2-"):
			has_d2 = true
			break
	assert_true(has_d2)
	print("OK deadline expiration; offers refresh at midnight")
	n += 1

	# Test 10
	var s10 = stocked()
	var before10 = clone(s10)
	var bad_cmds = [
		{ "type": "trade", "item": "raw:iron", "side": "buy", "quantity": -1 },
		{ "type": "trade", "item": "raw:iron", "side": "buy", "quantity": 1000 },
		{ "type": "trade", "item": "unknown", "side": "buy", "quantity": 1 },
		{ "type": "machine", "slot": 9, "action": "buy" }
	]
	for bc in bad_cmds:
		assert_eq(Fixtures.perform(s10, bc).ok, false)
	assert_eq(JSON.stringify(s10), JSON.stringify(before10))
	do_it(s10, { "type": "trade", "item": "raw:iron", "side": "buy", "quantity": 10 })
	assert_eq(s10.raw.iron, 36)
	assert_eq(s10.incoming.iron, 10)
	assert_true(s10.money < before10.money)
	print("OK valid purchases preserve cash/capacity; invalid commands do nothing")
	n += 1

	# Test 11
	var s11 = staffed()
	s11.money = 10000
	s11.storage.raw = 5
	s11.storage.goods = 5
	s11.raw.iron = 200
	s11.raw.zinc = 70
	s11.logistics = 2
	for i in range(1, 6):
		FoundryEngine.act(s11, i, "buy")
		hire(s11, i)
	for i in range(6):
		FoundryEngine.act(s11, i, "auto", { "enabled": true })
	var a11 = clone(s11)
	var b11 = clone(s11)
	FoundryEngine.tick(a11, 180.0)
	for i in range(10800):
		FoundryEngine.tick(b11, 1.0 / 60.0)
	assert_near(a11.clock, b11.clock, 1e-5)
	assert_eq(a11.made, b11.made)
	assert_eq(JSON.stringify(a11.goods), JSON.stringify(b11.goods))
	assert_eq(JSON.stringify(a11.raw), JSON.stringify(b11.raw))
	assert_eq(a11.money, b11.money)
	assert_eq(a11.shiftChanges, b11.shiftChanges)
	print("OK large and frame-sized steps yield the same multi-machine production")
	n += 1

	# Test 12
	var s12 = staffed()
	s12.goods.clean_ring = 2
	do_it(s12, { "type": "limit", "product": "clean_ring", "quantity": 1, "minPrice": 999 })
	FoundryEngine.act(s12, 0, "cast")
	FoundryEngine.tick(s12, 5.0)
	var r12 = FoundryEngine.restore(JSON.stringify(s12))
	assert_eq(JSON.stringify(r12.raw), JSON.stringify(s12.raw))
	assert_eq(JSON.stringify(r12.goods), JSON.stringify(s12.goods))
	assert_eq(JSON.stringify(r12.delivery), JSON.stringify(s12.delivery))
	assert_eq(JSON.stringify(r12.limits), JSON.stringify(s12.limits))
	FoundryEngine.tick(r12, 30.0)
	assert_eq(r12.machines[0].state, "idle")
	var old12 = {
		"version": 2,
		"money": 3210,
		"sold": 35,
		"selected": 0,
		"machines": [{ "level": 3, "state": "idle", "elapsed": 0, "served": false }, null, null, null, null, null]
	}
	var m12 = FoundryEngine.restore(JSON.stringify(old12))
	assert_eq(m12.money, 3210)
	assert_eq(m12.sold, 35)
	assert_eq(m12.machines[0].level, 3)
	assert_eq(m12.raw.iron, 36)
	assert_true(m12.milestones.has("sales"))
	print("OK saved active work, orders and inventory round-trip; legacy progress migrates")
	n += 1

	# Test 13
	var s13 = stocked()
	s13.goods.clean_iron_pipe = 1
	do_it(s13, { "type": "limit", "product": "clean_iron_pipe", "quantity": 1, "minPrice": 1 })
	var a13 = clone(s13)
	var b13 = clone(s13)
	FoundryEngine.tick(a13, 15.0)
	for i in range(900):
		FoundryEngine.tick(b13, 1.0 / 60.0)
	assert_eq(a13.money, b13.money)
	assert_eq(a13.sold, b13.sold)
	print("OK quote boundary executes at the same price for small and large time steps")
	n += 1

	# Test 14
	var s14 = stocked()
	var before14 = clone(s14)
	for item_bad in ["raw:constructor", "goods:__proto__"]:
		assert_eq(Fixtures.perform(s14, { "type": "trade", "item": item_bad, "side": "buy", "quantity": 1 }).ok, false)
	assert_eq(JSON.stringify(s14), JSON.stringify(before14))
	print("OK unknown inherited catalog keys are rejected without corrupting funds")
	n += 1

	# Test 15
	var s15 = hire(Fixtures.fresh())
	assert_eq(s15.raw.iron, 0)
	assert_eq(s15.incoming.iron, 36)
	assert_true(FoundryEngine.can_cast(s15, 0) != "")
	do_it(s15, { "type": "store", "material": "iron", "quantity": 36 })
	do_it(s15, { "type": "store", "material": "zinc", "quantity": 16 })
	assert_eq(FoundryEngine.can_cast(s15, 0), "")
	do_it(s15, { "type": "trade", "item": "raw:iron", "side": "buy", "quantity": 30 })
	assert_eq(s15.raw.iron, 36)
	assert_eq(Fixtures.perform(s15, { "type": "store", "material": "iron", "quantity": 30 }).ok, false)
	var copper15 = FoundryEngine.bin_capacity(s15, "copper")
	do_it(s15, { "type": "expandBin", "material": "iron" })
	assert_eq(FoundryEngine.bin_capacity(s15, "iron"), 120)
	assert_eq(FoundryEngine.bin_capacity(s15, "copper"), copper15)
	do_it(s15, { "type": "store", "material": "iron", "quantity": 30 })
	assert_eq(s15.raw.iron, 66)
	assert_eq(s15.incoming.iron, 0)
	print("OK deliveries are unavailable until stored; individual bin limits and upgrades")
	n += 1

	# Test 16
	var s16 = stocked()
	s16.money = 10000
	do_it(s16, { "type": "trade", "item": "raw:iron", "side": "buy", "quantity": 160 })
	assert_eq(Fixtures.perform(s16, { "type": "trade", "item": "raw:copper", "side": "buy", "quantity": 1 }).ok, false)
	do_it(s16, { "type": "trade", "item": "raw:iron", "side": "sell", "quantity": 170 })
	assert_eq(s16.incoming.iron, 0)
	assert_eq(s16.raw.iron, 26)
	print("OK receiving capacity and raw sale preserve stock across both locations")
	n += 1

	# Test 17
	var s17 = stocked()
	s17.money = 10000
	FoundryEngine.tick(s17, 180.0)
	assert_eq(s17.money, 10000)
	assert_eq(s17.payroll.accrued, 224.0)
	assert_eq(s17.payroll.history.size(), 0)
	FoundryEngine.tick(s17, FoundryEngine.next_pay(s17) - s17.clock)
	assert_eq(s17.money, 8504)
	assert_eq(s17.payroll.paid, 1496)
	assert_eq(s17.payroll.history.size(), 1)
	assert_eq(s17.payroll.history[0].weekly, true)
	FoundryEngine.tick(s17, Constants.WEEK)
	assert_eq(s17.payroll.history[0].due, 1568)
	assert_eq(s17.payroll.paid, 3064)
	print("OK base wages accrue across all shifts and pay only at the weekly boundary")
	n += 1

	# Test 18
	var s18 = staffed()
	s18.money = 5
	s18.machines[0].product = "ring"
	FoundryEngine.act(s18, 0, "cast")
	FoundryEngine.tick(s18, FoundryEngine.next_pay(s18) - s18.clock)
	assert_eq(s18.machines[0].state, "idle")
	assert_eq(s18.goods.ring, 1)
	assert_eq(s18.payroll.debt, 1865)
	assert_eq(Fixtures.perform(s18, { "type": "trade", "item": "goods:ring", "side": "sell", "quantity": 1 }).ok, false)
	s18.goods.clean_ring = 1
	do_it(s18, { "type": "trade", "item": "goods:clean_ring", "side": "sell", "quantity": 1 })
	assert_true(FoundryEngine.can_cast(s18, 0).contains("mzdy"))
	var accrued18 = s18.payroll.accrued
	FoundryEngine.tick(s18, 120.0)
	assert_eq(s18.payroll.accrued, accrued18)
	s18.money = 2000
	do_it(s18, { "type": "payWages" })
	assert_eq(s18.payroll.debt, 0)
	assert_eq(FoundryEngine.can_cast(s18, 0), "")
	print("OK weekly debt stops new work but preserves finished goods and resumes after payment")
	n += 1

	# Test 19
	var s19 = Fixtures.fresh()
	s19.payroll.accrued = 12.5
	s19.payroll.debt = 27
	s19.payroll.paid = 5
	s19.bins.copper = 2
	var r19 = FoundryEngine.restore(JSON.stringify(s19))
	assert_eq(r19.version, 14)
	assert_eq(JSON.stringify(r19.incoming), JSON.stringify(s19.incoming))
	assert_eq(JSON.stringify(r19.bins), JSON.stringify(s19.bins))
	assert_eq(JSON.stringify(r19.payroll), JSON.stringify(s19.payroll))
	var old19 = stocked()
	old19.version = 3
	old19.clock = 100.0
	old19.storage.raw = 2
	old19.raw.iron = 350
	var migrated19 = FoundryEngine.restore(JSON.stringify(old19))
	assert_eq(migrated19.raw.iron, 350)
	assert_true(FoundryEngine.bin_capacity(migrated19, "iron") >= 350)
	assert_eq(FoundryEngine.used(migrated19, "incoming"), 0)
	assert_eq(migrated19.payroll.accrued, 0.0)
	FoundryEngine.tick(migrated19, 5.0)
	assert_eq(migrated19.payroll.paid, 0)
	assert_near(migrated19.payroll.accrued, 16.0 / 3.0, 1e-6)
	print("OK warehouse/payroll save restores without duplicating or resetting debts")
	n += 1

	# Test 20
	var crew_names = []
	for p in Constants.CREWS: crew_names.append(p.name)
	assert_eq(crew_names, ["Miči", "Maslo", "Matino"])
	var furn_names = []
	for p in Constants.FURNACE_CREWS: furn_names.append(p.name)
	assert_eq(furn_names, ["Ivan", "Palo", "Adino"])
	var wh_set = {}
	for p in Constants.WAREHOUSE_CREWS: wh_set[p.name] = true
	assert_eq(wh_set.keys().size(), 3)
	for i in range(3):
		var team = FoundryEngine.staff({ "clock": 45.0 + float(i) * 60.0 })
		var wh_count = 0
		var fm_count = 0
		for member in team:
			if member.role == "warehouse": wh_count += 1
			if member.role == "foreman": fm_count += 1
		assert_eq(wh_count, 1)
		assert_eq(fm_count, 1)
		assert_eq(team.size(), 4)
	for role_k in Constants.WAGES.keys():
		assert_eq(FoundryEngine.wage(role_k, 0), FoundryEngine.wage(role_k, 1))
		assert_eq(FoundryEngine.wage(role_k, 2), FoundryEngine.wage(role_k, 0) * 1.5)
	print("OK renamed crews have one warehouse worker and one foreman; all roles earn +50% at night")
	n += 1

	# Test 21
	var s21 = stocked()
	s21.money = 10000
	FoundryEngine.tick(s21, 150.0)
	assert_eq(s21.payroll.accrued, 176.0)
	var r21 = FoundryEngine.restore(JSON.stringify(s21))
	assert_eq(JSON.stringify(r21.payroll), JSON.stringify(s21.payroll))
	FoundryEngine.tick(r21, FoundryEngine.next_pay(r21) - r21.clock)
	assert_eq(r21.payroll.history[0].due, 1496)
	var again21 = FoundryEngine.restore(JSON.stringify(r21))
	FoundryEngine.tick(again21, 0.1)
	assert_eq(again21.payroll.paid, 1496)
	assert_eq(again21.payroll.history.size(), 1)
	print("OK weekly accrued wages survive reload and pay exactly once")
	n += 1

	# Test 22
	var old22 = stocked()
	old22.version = 4
	old22.clock = 195.0
	old22.payroll = {
		"accrued": 16.0,
		"paid": 64,
		"debt": 0,
		"history": [{ "clock": 165.0, "crew": 1, "due": 32, "paid": 32 }]
	}
	old22.incoming.iron = 9
	old22.bins.iron = 2
	var r22 = FoundryEngine.restore(JSON.stringify(old22))
	assert_eq(r22.money, old22.money)
	assert_eq(r22.payroll.accrued, 16.0)
	assert_eq(JSON.stringify(r22.raw), JSON.stringify(old22.raw))
	assert_eq(JSON.stringify(r22.incoming), JSON.stringify(old22.incoming))
	assert_eq(r22.payroll.history[0].team, false)
	FoundryEngine.tick(r22, 30.0)
	assert_eq(r22.payroll.accrued, 64.0)
	assert_eq(r22.payroll.paid, 64)
	old22.payroll.debt = 27
	assert_eq(FoundryEngine.restore(JSON.stringify(old22)).payroll.debt, 27)
	print("OK v4 upgrade preserves earned wages and stock without retroactive charges")
	n += 1

	# Test 23
	var s23 = stocked()
	assert_eq(Constants.FOREMEN[FoundryEngine.foreman_shift(s23)].name, "Mišo (Majster)")
	assert_eq(FoundryEngine.next_foreman_change(s23), 135.0)
	FoundryEngine.tick(s23, 60.0)
	assert_eq(FoundryEngine.shift(s23), 1)
	assert_eq(FoundryEngine.foreman_shift(s23), 0)
	FoundryEngine.tick(s23, 29.999)
	assert_eq(FoundryEngine.foreman_shift(s23), 0)
	FoundryEngine.tick(s23, 0.001)
	assert_eq(FoundryEngine.clock_text(s23), "18:00")
	assert_eq(FoundryEngine.shift(s23), 1)
	assert_eq(FoundryEngine.foreman_shift(s23), 1)
	assert_eq(FoundryEngine.next_foreman_change(s23), 225.0)
	assert_eq(FoundryEngine.staff(s23)[-1].name, "Miro (Majster)")
	FoundryEngine.tick(s23, 30.0)
	assert_eq(FoundryEngine.shift(s23), 2)
	assert_eq(FoundryEngine.foreman_shift(s23), 1)
	FoundryEngine.tick(s23, 15.0)
	assert_eq(FoundryEngine.clock_text(s23), "00:00")
	assert_eq(FoundryEngine.foreman_shift(s23), 1)
	FoundryEngine.tick(s23, 45.0)
	assert_eq(FoundryEngine.clock_text(s23), "06:00")
	assert_eq(FoundryEngine.foreman_shift(s23), 0)
	assert_eq(FoundryEngine.next_foreman_change(s23), 315.0)
	print("OK foremen alternate at 06 and 18, independently of the 8-hour crews")
	n += 1

	# Test 24
	var s24 = stocked()
	s24.money = 10000
	FoundryEngine.tick(s24, 90.0)
	assert_eq(s24.payroll.history.size(), 0)
	assert_eq(s24.payroll.foremenAccrued, [30.0, 0.0])
	var r24 = FoundryEngine.restore(JSON.stringify(s24))
	assert_eq(JSON.stringify(r24.payroll), JSON.stringify(s24.payroll))
	FoundryEngine.tick(r24, 90.0)
	assert_eq(r24.payroll.foremenAccrued, [30.0, 40.0])
	assert_eq(r24.money, 10000)
	FoundryEngine.tick(r24, FoundryEngine.next_pay(r24) - r24.clock)
	assert_eq(r24.payroll.history[0].foremen, [210.0, 257.5])
	assert_eq(r24.payroll.paid, 1496)
	print("OK only on-duty foremen earn wages; both totals accumulate until weekly payday")
	n += 1

	# Test 25
	var old25 = stocked()
	old25.version = 5
	old25.clock = 150.0
	old25.payroll = {
		"accrued": 48.0,
		"paid": 64,
		"debt": 0,
		"history": [{ "clock": 105.0, "crew": 0, "due": 64, "paid": 64, "team": true }]
	}
	var r25 = FoundryEngine.restore(JSON.stringify(old25))
	assert_eq(r25.money, 1000)
	assert_eq(r25.payroll.accrued, 48.0)
	assert_eq(r25.payroll.foremenAccrued, [0.0, 0.0])
	FoundryEngine.tick(r25, 15.0)
	assert_eq(r25.payroll.accrued, 64.0)
	assert_eq(r25.payroll.paid, 64)
	assert_eq(r25.payroll.foremenAccrued, [0.0, 5.0])
	old25.payroll.debt = 17
	var debt25 = FoundryEngine.restore(JSON.stringify(old25))
	FoundryEngine.tick(debt25, 15.0)
	assert_eq(debt25.payroll.accrued, 48.0)
	assert_eq(debt25.payroll.debt, 17)
	print("OK v5 migration preserves cash, debts, history and wages already earned")
	n += 1

	print(str(n) + " simulation checks passed.")
	return true
