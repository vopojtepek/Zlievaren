class_name TestUpdate21
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

func run_all() -> bool:
	n = 0
	var s: Dictionary = FoundryEngine.fresh()
	var excluded: Array = ["warehouse", "washer", "foreman"]
	for role in excluded:
		var pos_key: String = ""
		for p in FoundryEngine.positions(s):
			if p.role == role:
				pos_key = p.key
				break
		if FoundryEngine.assigned(s, pos_key) == null:
			var hire_res: Dictionary = FoundryEngine.perform(s, {
				"type": "personnel",
				"action": "hire",
				"position": pos_key,
				"candidateId": s.hr.candidates[pos_key][0].id
			})
			assert_true(hire_res.ok, "hire must succeed")
		var e: Dictionary = FoundryEngine.assigned(s, pos_key)
		assert_true(not e.has("defect"), "excluded role must not have defect")
		e["defect"] = 15
		e["salary"] = 27.4

	for p in FoundryEngine.positions(s):
		var cands: Array = s.hr.candidates.get(p.key, [])
		for c in cands:
			if excluded.has(p.role):
				assert_true(not c.has("defect"), "excluded candidate must not have defect")
				c["defect"] = 12
			else:
				assert_true(int(c.defect) >= 1 and int(c.defect) <= 15, "defect in 1..15")

	var expected: Array = []
	for e in s.hr.employees:
		var emp_copy: Dictionary = e.duplicate(true)
		if excluded.has(emp_copy.role):
			emp_copy.erase("defect")
		expected.append(emp_copy)

	var restored: Dictionary = FoundryEngine.restore(JSON.stringify(s))
	assert_eq(JSON.stringify(restored.hr.employees), JSON.stringify(expected), "employees match")
	assert_eq(JSON.stringify(restored.payroll), JSON.stringify(s.payroll), "payroll matches")
	assert_eq(JSON.stringify(restored.hr.lines), JSON.stringify(s.hr.lines), "hr lines match")

	for p in FoundryEngine.positions(restored):
		var cands: Array = restored.hr.candidates.get(p.key, [])
		if excluded.has(p.role):
			for c in cands:
				assert_true(not c.has("defect"), "restored excluded candidate has no defect")
				assert_eq(c.salary, FoundryEngine.candidate_salary(p.role, null, c.absence), "candidate salary matches formula")

	assert_eq(JSON.stringify(FoundryEngine.restore(JSON.stringify(restored)).hr), JSON.stringify(restored.hr), "re-restore hr matches")
	print("OK removed traits migrate without losing people, salaries or payroll; remaining roles retain quality risk")
	n += 1
	print(str(n) + " update 21 checks passed.")
	return true
