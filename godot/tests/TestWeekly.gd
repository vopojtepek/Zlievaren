class_name TestWeekly
extends RefCounted

var count: int = 0

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

func rich() -> Dictionary:
	var s = Fixtures.fresh()
	s.money = 100000
	return s

func run_all() -> bool:
	count = 0

	# Test 1
	assert_eq(Fixtures.fresh().money, 1000)
	var checks: Array = [
		[45.0, 1, 1],
		[1259.9, 1, 7],
		[1260.0, 2, 8],
		[2519.9, 2, 14],
		[2520.0, 3, 15]
	]
	for chk in checks:
		var clk: float = chk[0]
		var exp_w: int = chk[1]
		var exp_d: int = chk[2]
		assert_eq(FoundryEngine.week({ "clock": clk }), exp_w)
		assert_eq(FoundryEngine.day({ "clock": clk }), exp_d)
	assert_eq(Constants.WEEK, 1260.0)
	print("OK new games start with 1000; weeks match seven calendar days")
	count += 1

	# Test 2
	var s2 = rich()
	FoundryEngine.tick(s2, 1214.99)
	assert_eq(s2.payroll.paid, 0)
	assert_eq(FoundryEngine.week(s2), 1)
	var saved = JSON.stringify(s2)
	FoundryEngine.tick(s2, 0.0)
	assert_eq(JSON.stringify(s2), saved)
	FoundryEngine.tick(s2, 0.01)
	assert_eq(FoundryEngine.week(s2), 2)
	assert_eq(FoundryEngine.day(s2), 8)
	assert_eq(FoundryEngine.clock_text(s2), "00:00")
	assert_eq(s2.payroll.paid, 1496)
	assert_eq(s2.payroll.history.size(), 1)
	var r2 = copy_state(s2)
	FoundryEngine.tick(r2, 45.0)
	assert_eq(r2.payroll.paid, 1496)
	assert_eq(r2.payroll.history.size(), 1)
	assert_eq(FoundryEngine.shift(r2), 0)
	print("OK payday happens once at midnight, not at shift changes; pause does nothing")
	count += 1

	# Test 3
	var s3 = rich()
	s3.version = 10
	s3.clock = 1250.0
	s3.money = 321
	s3.payroll = {
		"accrued": 33.0,
		"operatorAccrued": [9.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		"foremenAccrued": [0.0, 5.0],
		"paid": 777,
		"debt": 0,
		"history": [{
			"clock": 1245.0,
			"crew": 2,
			"due": 120,
			"paid": 120,
			"team": true,
			"operators": [{ "slot": 0, "name": "Emil", "amount": 24.0 }],
			"foremen": [0.0, 30.0]
		}]
	}
	var r3 = copy_state(s3)
	assert_eq(r3.money, 321)
	assert_eq(r3.payroll.paid, 777)
	assert_eq(r3.payroll.accrued, 33.0)
	assert_eq(r3.payroll.operatorByCrew[0][2], 9.0)
	assert_eq(r3.payroll.history[0].operators[0].name, "Emil")
	FoundryEngine.tick(r3, 10.0)
	assert_eq(r3.payroll.history[0].due, 49)
	assert_eq(r3.payroll.history[0].operators[0].name, "Emil")
	assert_eq(r3.money, 272)
	assert_eq(copy_state(r3).payroll.history[0].operators[0].name, "Emil")
	print("OK v10 migration preserves balances, pending wages, employee names and old history")
	count += 1

	# Test 4
	var s4 = rich()
	for slot in range(6):
		if slot > 0:
			FoundryEngine.act_machine(s4, slot, "buy")
		for crew in range(3):
			assert_eq(Fixtures.perform(s4, { "type": "employment", "action": "hire", "slot": slot, "crew": crew }).ok, true)
	s4.hr.rng = 202
	FoundryEngine.tick(s4, 1200.0)
	assert_true(s4.payroll.accrued > 3500.0)
	var r4 = copy_state(s4)
	assert_eq(JSON.stringify(r4.payroll), JSON.stringify(s4.payroll))
	assert_eq(JSON.stringify(r4.operators), JSON.stringify(s4.operators))
	FoundryEngine.tick(r4, 15.0)
	assert_eq(r4.payroll.history[0].due, 3740)
	assert_eq(r4.payroll.history[0].operators.size(), 18)
	FoundryEngine.tick(r4, 1260.0)
	assert_eq(r4.payroll.history[0].due, 3920)
	assert_eq(JSON.stringify(copy_state(r4).payroll), JSON.stringify(r4.payroll))
	print("OK large weekly wage accrual and individual employees survive reload without truncation")
	count += 1

	# Test 5
	var a5 = rich()
	var b5 = copy_state(a5)
	FoundryEngine.tick(a5, 2475.0)
	for i in range(148500):
		FoundryEngine.tick(b5, 1.0 / 60.0)
	assert_eq(a5.payroll.paid, b5.payroll.paid)
	assert_eq(a5.money, b5.money)
	assert_eq(FoundryEngine.week(a5), FoundryEngine.week(b5))
	assert_eq(a5.shiftChanges, b5.shiftChanges)
	assert_eq(a5.payroll.history.size(), 2)
	var a_dues = a5.payroll.history.map(func(h): return h.due)
	var b_dues = b5.payroll.history.map(func(h): return h.due)
	assert_eq(JSON.stringify(a_dues), JSON.stringify(b_dues))
	print("OK large and frame-sized updates agree across two weeks, shifts and foremen")
	count += 1

	# Test 6
	var s6 = rich()
	s6.version = 10
	s6.payroll.debt = 100
	s6.payroll.accrued = 20.0
	s6.money = 30
	var r6 = copy_state(s6)
	FoundryEngine.tick(r6, 30.0)
	assert_eq(r6.payroll.accrued, 20.0)
	Fixtures.perform(r6, { "type": "payWages" })
	assert_eq(r6.payroll.debt, 70)
	r6.money = 100
	Fixtures.perform(r6, { "type": "payWages" })
	assert_eq(r6.payroll.debt, 0)
	FoundryEngine.tick(r6, 15.0)
	assert_eq(r6.payroll.accrued, 36.0)
	print("OK old debts survive migration and partial repayments; wages resume only after settlement")
	count += 1

	print(str(count) + " weekly payroll checks passed.")
	return true
