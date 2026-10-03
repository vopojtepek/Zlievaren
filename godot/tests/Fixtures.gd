class_name Fixtures
extends RefCounted

static func fresh() -> Dictionary:
	var old: Dictionary = FoundryEngine.fresh()
	old.version = 11
	old.raw = FoundryEngine.empty_raw()
	old.incoming = { "iron": 36, "steel": 15, "copper": 8, "tin": 3, "zinc": 16 }
	old.erase("hr")
	var s: Dictionary = FoundryEngine.restore(JSON.stringify(old))
	s.hr.rng = 202
	for e in s.hr.employees:
		e.absence = 1.0
		if FoundryEngine.has_defect(e.role):
			e.defect = 1
	return s

static func perform(s: Dictionary, c: Dictionary) -> Dictionary:
	if c.get("type") == "washer":
		for crew in range(3):
			var pos_key: String = FoundryEngine.position_key("washer", crew)
			if FoundryEngine.assigned(s, pos_key) == null:
				var candidate: Dictionary = s.hr.candidates[pos_key][0]
				candidate.absence = 1.0
				FoundryEngine.perform(s, { "type": "personnel", "action": "hire", "position": pos_key, "candidateId": candidate.id })
	
	if c.get("type") == "employment" and (c.get("slot") is int or c.get("slot") is float) and int(c.slot) >= 0 and int(c.slot) < 6 and (c.get("crew") is int or c.get("crew") is float) and int(c.crew) >= 0 and int(c.crew) < 3:
		var pos_key: String = FoundryEngine.position_key("operator", int(c.crew), int(c.slot))
		if c.get("action") == "hire":
			var cands = s.hr.candidates.get(pos_key)
			if cands is Array and cands.size() > 0:
				var candidate: Dictionary = cands[0]
				candidate.salary = 16.0
				candidate.defect = 1
				candidate.absence = 1.0
				candidate.name = Constants.OPERATORS[int(c.slot)][int(c.crew)]
				return FoundryEngine.perform(s, { "type": "personnel", "action": "hire", "position": pos_key, "candidateId": candidate.id })
		elif c.get("action") == "dismiss":
			var e: Variant = FoundryEngine.assigned(s, pos_key)
			if e != null:
				return FoundryEngine.perform(s, { "type": "personnel", "action": "dismiss", "employeeId": e.id })

	return FoundryEngine.perform(s, c)
