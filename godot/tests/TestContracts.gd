class_name TestContracts
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

func act(s: Dictionary, c: Dictionary, action: String) -> Dictionary:
	return Fixtures.perform(s, { "type": "contract", "id": c.id, "action": action })

func fresh() -> Dictionary:
	var s: Dictionary = Fixtures.fresh()
	s.money = 10000
	return s

func run_all() -> bool:
	n = 0

	# Test 1
	var s1 = fresh()
	var c1 = s1.contracts[0]
	assert_eq(c1.offerDeadline, s1.clock + 90.0)
	FoundryEngine.tick(s1, 89.999)
	assert_eq(c1.status, "offer")
	FoundryEngine.tick(s1, 0.001)
	assert_eq(c1.status, "lapsed")
	assert_eq(act(s1, c1, "accept").ok, false)
	assert_eq(FoundryEngine.relationship(s1, c1.buyer).score, 0)
	assert_eq(s1.reputation, 0)
	print("OK offer expires at 90 seconds without relationship penalty; cannot accept at boundary")
	n += 1

	# Test 2
	var s2 = fresh()
	var c2 = s2.contracts[0]
	FoundryEngine.tick(s2, 89.0)
	assert_eq(act(s2, c2, "accept").ok, true)
	assert_eq(c2.acceptedAt, 134.0)
	assert_eq(c2.deadline, 269.0)
	FoundryEngine.tick(s2, 2.0)
	assert_eq(c2.status, "active")
	assert_eq(act(s2, c2, "accept").ok, false)
	print("OK acceptance starts a fresh 135-second delivery deadline, independent of offer deadline")
	n += 1

	# Test 3
	var s3 = fresh()
	var c3 = s3.contracts[0]
	var payout3 = c3.payout
	act(s3, c3, "accept")
	s3.goods[c3.product] = c3.quantity
	var money3 = s3.money
	assert_eq(act(s3, c3, "fulfill").ok, true)
	assert_eq(s3.money, money3 + payout3)
	assert_eq(FoundryEngine.relationship(s3, c3.buyer).score, 10)
	assert_eq(FoundryEngine.relationship(s3, c3.buyer).delivered, 1)
	assert_eq(act(s3, c3, "fulfill").ok, false)
	for b in Constants.COMPANIES:
		if b != c3.buyer:
			assert_eq(FoundryEngine.relationship(s3, b).score, 0)
	assert_eq(JSON.stringify(copy_state(s3).relationships), JSON.stringify(s3.relationships))
	print("OK on-time delivery rewards only that firm, once; unrelated companies unchanged")
	n += 1

	# Test 4
	var s4 = fresh()
	var c4 = s4.contracts[0]
	act(s4, c4, "accept")
	FoundryEngine.tick(s4, 135.0)
	assert_eq(c4.status, "expired")
	assert_eq(FoundryEngine.relationship(s4, c4.buyer).score, -15)
	assert_eq(FoundryEngine.relationship(s4, c4.buyer).missed, 1)
	var r4 = copy_state(s4)
	FoundryEngine.tick(r4, 30.0)
	assert_eq(FoundryEngine.relationship(r4, c4.buyer).score, -15)
	assert_eq(FoundryEngine.relationship(r4, c4.buyer).missed, 1)
	print("OK missed delivery subtracts trust once, including at midnight and after reload")
	n += 1

	# Test 5
	var good = fresh()
	var neutral = copy_state(good)
	var bad = copy_state(good)
	for b in Constants.COMPANIES:
		good.relationships[b].score = 100
		bad.relationships[b].score = -100
	for s_elem in [good, neutral, bad]:
		FoundryEngine.tick(s_elem, 135.0)
	for i in range(3):
		var g_c = good.contracts[i]
		var m_c = neutral.contracts[i]
		var b_c = bad.contracts[i]
		assert_eq(g_c.quantity, m_c.quantity * 3)
		assert_eq(g_c.payout, int(round(float(FoundryEngine.contract_payout(g_c.product, g_c.quantity)) * 1.3)))
		assert_true(float(g_c.payout) / float(g_c.quantity) > float(m_c.payout) / float(m_c.quantity))
		assert_true(b_c.quantity < m_c.quantity)
		assert_true(float(b_c.payout) / float(b_c.quantity) < float(m_c.payout) / float(m_c.quantity))
	print("OK better relations increase quantity and unit payout; bad relations reduce both")
	n += 1

	# Test 6
	var s6 = fresh()
	var c6 = s6.contracts[0]
	var terms = [c6.quantity, c6.payout, c6.bonus]
	s6.relationships[c6.buyer].score = 100
	act(s6, c6, "accept")
	assert_eq(JSON.stringify([c6.quantity, c6.payout, c6.bonus]), JSON.stringify(terms))
	print("OK published and accepted terms are locked when the relationship changes")
	n += 1

	# Test 7
	var s7 = fresh()
	var c7 = s7.contracts[0]
	act(s7, c7, "accept")
	s7.version = 8
	s7.erase("relationships")
	for ct in s7.contracts:
		ct.erase("offerDeadline")
		ct.erase("acceptedAt")
		ct.erase("bonus")
	var r7 = copy_state(s7)
	assert_eq(r7.money, s7.money)
	assert_eq(r7.contracts[0].deadline, c7.deadline)
	assert_eq(r7.contracts[1].offerDeadline, s7.clock + 90.0)
	FoundryEngine.tick(r7, 12.0)
	var again7 = copy_state(r7)
	assert_eq(again7.contracts[1].offerDeadline, s7.clock + 90.0)
	assert_eq(FoundryEngine.relationship(again7, c7.buyer).score, 0)
	print("OK legacy saves preserve cash and active deadlines; old offers gain one fixed acceptance window")
	n += 1

	# Test 8
	var s8 = fresh()
	act(s8, s8.contracts[0], "accept")
	var a8 = copy_state(s8)
	var b8 = copy_state(s8)
	FoundryEngine.tick(a8, 240.0)
	for i in range(14400):
		FoundryEngine.tick(b8, 1.0 / 60.0)
	assert_eq(JSON.stringify(a8.relationships), JSON.stringify(b8.relationships))
	var a_mapped = a8.contracts.map(func(c): return [c.id, c.status, c.payout, c.quantity])
	var b_mapped = b8.contracts.map(func(c): return [c.id, c.status, c.payout, c.quantity])
	assert_eq(JSON.stringify(a_mapped), JSON.stringify(b_mapped))
	print("OK large and frame-sized ticks agree on deadlines, trust and daily offer rewards")
	n += 1

	# Test 9
	var s9 = fresh()
	FoundryEngine.tick(s9, 130.0)
	assert_eq(Fixtures.perform(s9, { "type": "unlock", "product": "steel_pipe" }).ok, true)
	var c9 = s9.contracts[s9.contracts.size() - 1]
	FoundryEngine.tick(s9, 5.0)
	var in_contracts: bool = false
	for ct in s9.contracts:
		if ct.id == c9.id:
			in_contracts = true
			break
	assert_true(in_contracts)
	assert_eq(c9.status, "offer")
	assert_eq(c9.offerDeadline, 265.0)
	print("OK late unlock offers survive midnight until their own acceptance deadline")
	n += 1

	var guards = fresh()
	assert_true(act(guards, guards.contracts[0], "accept").ok)
	assert_true(act(guards, guards.contracts[1], "accept").ok)
	assert_eq(act(guards, guards.contracts[2], "accept").ok, false)
	var guarded = guards.contracts[0]
	guards.goods[guarded.product] = guarded.quantity
	guards.limits.append({"id": "reserved-test", "product": guarded.product, "quantity": 1, "minPrice": 99999})
	var before_money = guards.money
	assert_eq(act(guards, guarded, "fulfill").ok, false)
	assert_eq(guards.money, before_money)
	guards.limits.clear()
	assert_true(act(guards, guarded, "fulfill").ok)
	assert_eq(act(guards, guarded, "fulfill").ok, false)
	var unstaffed = FoundryEngine.fresh()
	var pending = unstaffed.contracts[0]
	act(unstaffed, pending, "accept")
	unstaffed.goods[pending.product] = pending.quantity
	assert_eq(act(unstaffed, pending, "fulfill").message, "Na expedíciu zákazky chýba skladník. Otvor Kanceláriu.")
	assert_eq(pending.status, "active")
	assert_eq(unstaffed.goods[pending.product], pending.quantity)
	n += 1
	var rounding = fresh()
	var buyer = Constants.COMPANIES[0]
	# Expected results from the web's Math.round(score * .3).
	for pair in [[-100, -30], [-95, -28], [-15, -4], [-5, -1], [0, 0], [5, 2], [15, 5], [100, 30]]:
		rounding.relationships[buyer].score = pair[0]
		assert_eq(FoundryEngine.company_terms(rounding, buyer).bonus, pair[1])
		var offer = FoundryEngine.make_offer(rounding, "rounding", "clean_iron_pipe", 4, buyer)
		assert_eq(offer.bonus, pair[1])
	n += 1
	print("OK capacity, reservations, warehouse staffing and JavaScript bonus rounding")
	print(str(n) + " company contract checks passed.")
	return true
