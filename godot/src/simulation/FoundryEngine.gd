class_name FoundryEngine
extends RefCounted

const C = preload("res://src/core/Constants.gd")

static func failure_risk(m: Variant) -> float:
	if m is Dictionary and (m.product == "iron_pipe" or m.product == "steel_pipe"):
		var risks = [0.3, 0.2, 0.1]
		return risks[int(m.level) - 1]
	return 0.0

static func contract_payout(product: String, quantity: int) -> int:
	var base_p: float = C.PRODUCTS[product].base
	var unit: float = round(base_p * 1.3)
	return int(max(1, round(unit * float(quantity) * 0.75)))

static func roll(s: Dictionary) -> float:
	# 32-bit unsigned math: (1664525 * s.rng + 1013904223) & 0xFFFFFFFF
	var next_val: int = (1664525 * int(s.rng) + 1013904223) & 0xFFFFFFFF
	s.rng = next_val
	return float(next_val) / 4294967296.0

static func saleable(id: String) -> bool:
	return C.PRODUCTS.has(id) and not C.WASH.outputs.has(id)

static func empty_staff() -> Array:
	var arr: Array = []
	for i in range(C.SLOTS):
		arr.append([false, false, false])
	return arr

static func empty_pallets() -> Array:
	var arr: Array = []
	for i in range(C.SLOTS):
		var p_dict: Dictionary = {}
		for pid: String in C.PRODUCTS.keys():
			p_dict[pid] = 0
		arr.append(p_dict)
	return arr

static func empty_raw() -> Dictionary:
	var dict: Dictionary = {}
	for id: String in C.MATERIALS.keys():
		dict[id] = 0
	return dict

static func empty_goods() -> Dictionary:
	var dict: Dictionary = {}
	for id: String in C.PRODUCTS.keys():
		dict[id] = 0
	return dict

static func new_washer() -> Dictionary:
	return {
		"product": "iron_pipe",
		"active": null,
		"elapsed": 0.0,
		"auto": false,
		"cleaned": 0,
		"lastProduct": null,
		"lastAt": null
	}

static func wash_stage(s: Dictionary) -> String:
	var w: Dictionary = s.washer
	if w.active == null:
		return "idle"
	if w.elapsed < C.WASH.load:
		return "loading"
	if w.elapsed < C.WASH.washEnd:
		return "washing"
	return "ejecting"

static func operator_count(s: Dictionary, crew: int) -> int:
	var count: int = 0
	for i in range(C.SLOTS):
		if s.machines[i] != null and s.operators[i][crew] == true:
			count += 1
	return count

static func shift_wages(crew: int, s: Dictionary) -> float:
	if s.get("hr"):
		var total: float = 0.0
		for e in s.hr.employees:
			if e.active and e.role != "foreman" and e.crew == crew:
				total += regular_shift_pay(e)
		var fm_pay: float = 0.0
		var fm0 = assigned(s, position_key("foreman", 0))
		var fm1 = assigned(s, position_key("foreman", 1))
		var sal0: float = float(fm0.salary) if fm0 != null else 0.0
		var sal1: float = float(fm1.salary) if fm1 != null else 0.0
		if crew == 1:
			fm_pay = (sal0 + sal1) / 2.0
		else:
			var target_sal: float = sal1 if crew == 2 else sal0
			fm_pay = target_sal * (1.5 if crew == 2 else 1.0)
		return total + fm_pay
	return 0.0

static func wage(role: String, crew: int) -> float:
	return float(C.WAGES[role]) * (1.5 if crew == 2 else 1.0)

static func foreman_shift(s: Dictionary) -> int:
	var cycle: int = int(floor((s.clock - 45.0 + C.EPS) / 90.0))
	return ((cycle % 2) + 2) % 2

static func next_foreman_change(s: Dictionary) -> float:
	return float((int(floor((s.clock - 45.0 + C.EPS) / 90.0)) + 1) * 90 + 45)

static func foreman_pay(i: int) -> float:
	var f: Dictionary = C.FOREMEN[i]
	return float(f.dayHours * wage("foreman", 0) + f.nightHours * wage("foreman", 2)) / 8.0

static func shift_staff(crew: int) -> Array:
	var crw: Dictionary = C.CREWS[crew].duplicate(true)
	crw["role"] = "ladle"
	crw["job"] = "Obsluha panvy"
	var f_crw: Dictionary = C.FURNACE_CREWS[crew].duplicate(true)
	f_crw["role"] = "furnace"
	f_crw["job"] = "Obsluha pece"
	var w_crw: Dictionary = C.WAREHOUSE_CREWS[crew].duplicate(true)
	w_crw["role"] = "warehouse"
	w_crw["job"] = "Skladník"
	return [crw, f_crw, w_crw]

static func staff(s: Dictionary) -> Array:
	if s.get("hr"):
		var emps: Array = working_employees(s)
		var res: Array = []
		for e in emps:
			res.append(profile(e))
		return res
	var res: Array = []
	res.append_array(shift_staff(shift(s)))
	if s.has("machines") and s.machines is Array:
		for i in range(s.machines.size()):
			var op = operator(s, i)
			if op != null:
				res.append(op)
	var fm: Dictionary = C.FOREMEN[foreman_shift(s)].duplicate(true)
	fm["role"] = "foreman"
	fm["job"] = "Dohľad nad prevádzkou"
	res.append(fm)
	return res

static func next_shift(s: Dictionary) -> float:
	return float((int(floor((s.clock - 45.0 + C.EPS) / 60.0)) + 1) * 60 + 45)

static func week(s: Dictionary) -> int:
	return int(floor((s.clock + C.EPS) / C.WEEK)) + 1

static func next_pay(s: Dictionary) -> float:
	return float(week(s)) * C.WEEK

static func day(s: Dictionary) -> int:
	return int(floor((s.clock + C.EPS) / C.DAY)) + 1

static func hour(s: Dictionary) -> float:
	return fmod(s.clock, C.DAY) / C.DAY * 24.0

static func shift(s: Dictionary) -> int:
	var cycle: int = int(floor((s.clock - 45.0 + C.EPS) / 60.0))
	return ((cycle % 3) + 3) % 3

static func daylight(s: Dictionary) -> float:
	var h: float = hour(s)
	return clampf((sin((h - 6.0) / 24.0 * PI * 2.0) + 0.2) / 1.2, 0.0, 1.0)

static func clock_text(s: Dictionary) -> String:
	var minutes: int = int(floor(fmod(s.clock, C.DAY) / C.DAY * 1440.0 + C.EPS))
	var hh: int = (minutes / 60) % 24
	var mm: int = minutes % 60
	return "%02d:%02d" % [hh, mm]

static func occupied(s: Dictionary) -> int:
	var count: int = 0
	for m in s.machines:
		if m != null:
			count += 1
	return count

static func price(s: Dictionary) -> int:
	return 320 + (occupied(s) - 1) * 100

static func upgrade_price(m: Dictionary) -> int:
	return 180 if m.level == 1 else 300

static func duration(level: int, product: String = "iron_pipe") -> float:
	var diffs = [0, 6, 11]
	return maxf(16.0, float(C.PRODUCTS[product].seconds - diffs[level - 1]))

static func machine() -> Dictionary:
	return {
		"level": 1,
		"elapsed": 0.0,
		"state": "idle",
		"served": false,
		"product": "iron_pipe",
		"auto": false,
		"batchRisk": null,
		"failedElapsed": 0.0,
		"unloadElapsed": 0.0,
		"unloadCrew": 0,
		"employeeId": null,
		"unloadEmployeeId": null,
		"reject": false,
		"finishedAt": null
	}

static func event(s: Dictionary) -> Dictionary:
	return C.EVENTS[(day(s) - 1) % C.EVENTS.size()]

static func bin_open(s: Dictionary, id: String) -> bool:
	return C.MATERIALS.has(id) and s.binUnlocked.get(id, true) != false

static func bin_capacity(s: Dictionary, id: String) -> int:
	if bin_open(s, id):
		return int(C.BIN_BASE[id]) * (1 + int(s.bins[id]))
	return 0

static func bin_upgrade_price(s: Dictionary, id: String) -> int:
	return 120 * (int(s.bins[id]) + 1)

static func capacity(s: Dictionary, kind: String) -> int:
	if kind == "raw":
		var total: int = 0
		for id: String in C.MATERIALS.keys():
			total += bin_capacity(s, id)
		return total
	elif kind == "incoming":
		return 160 + int(s.storage.raw) * 120
	else:
		return 24 + int(s.storage.goods) * 24

static func reserved_output(s: Dictionary) -> int:
	var count: int = 0
	for m in s.machines:
		if m != null and (m.state == "working" or m.state == "ready" or m.state == "unloading"):
			count += 1
	if s.get("washer") and s.washer.get("active") != null:
		count += 1
	return count

static func used(s: Dictionary, kind: String) -> int:
	var total: int = 0
	for v in s[kind].values():
		total += int(v)
	return total

static func reserved(s: Dictionary, id: String) -> int:
	var total: int = 0
	for o in s.limits:
		if o.product == id:
			total += int(o.quantity)
	return total

static func available(s: Dictionary, id: String) -> int:
	return int(max(0, s.goods.get(id, 0) - reserved(s, id)))

static func logistics(s: Dictionary) -> float:
	return 1.0 + float(s.logistics) * 0.25

static func temperature(m: Variant) -> int:
	if m == null or m.state == "idle" or (m.state == "working" and m.elapsed <= C.FLOW.carryEnd):
		return 20
	if m.state == "ready" or m.state == "unloading":
		return 180
	if m.state == "failed":
		var peak_f: float = C.PRODUCTS[m.product].temp
		return int(round(peak_f - (peak_f - 320.0) * float(m.failedElapsed) / C.FAILURE_SECONDS))
	var peak: float = C.PRODUCTS[m.get("product", "iron_pipe")].temp
	var dur: float = duration(m.level, m.product)
	if m.elapsed < C.FLOW.pourEnd:
		return int(round(20.0 + (peak - 20.0) * (m.elapsed - C.FLOW.carryEnd) / (C.FLOW.pourEnd - C.FLOW.carryEnd)))
	else:
		var exponent: float = -log((peak - 20.0) / 160.0) * (m.elapsed - C.FLOW.pourEnd) / (dur - C.FLOW.pourEnd)
		return int(round(20.0 + (peak - 20.0) * exp(exponent)))

static func stage(m: Variant) -> String:
	if m == null:
		return "empty"
	if m.state != "working":
		return m.state
	if m.elapsed < C.FLOW.spinup - C.EPS:
		return "spinup"
	if not m.served:
		return "waiting"
	if m.elapsed < C.FLOW.loadEnd - C.EPS:
		return "loading"
	if m.elapsed < C.FLOW.carryEnd - C.EPS:
		return "carrying"
	if m.elapsed < C.FLOW.pourEnd - C.EPS:
		return "pouring"
	if m.elapsed < C.FLOW.castEnd - C.EPS:
		return "spinning"
	return "cooling"

static func ok_res(message: String) -> Dictionary:
	return { "ok": true, "message": message }

static func fail_res(message: String) -> Dictionary:
	return { "ok": false, "message": message }

static func log_msg(s: Dictionary, text: String, type: String = "info") -> void:
	s.ledger.insert(0, { "clock": s.clock, "text": text, "type": type })
	if s.ledger.size() > 40:
		s.ledger.resize(40)
	s.revision += 1

static func quote(s: Dictionary, item: String, at: Variant = null) -> Variant:
	var at_val: float = float(at) if at != null else float(s.clock)
	var parts: PackedStringArray = item.split(":")
	if parts.size() != 2:
		return null
	var kind: String = parts[0]
	var id: String = parts[1]
	var catalog: Dictionary = C.MATERIALS if kind == "raw" else (C.PRODUCTS if kind == "goods" else {})
	if not catalog.has(id):
		return null
	var cat_keys: Array = catalog.keys()
	var n: int = cat_keys.find(id) + (6 if kind == "goods" else 0)
	var step: int = int(floor((at_val + C.EPS) / C.QUOTE_INTERVAL))
	
	var value_func = func(t_val: int) -> int:
		var t_f: float = maxf(0.0, float(t_val))
		var day_idx: int = int(floor(t_f * C.QUOTE_INTERVAL / C.DAY)) % C.EVENTS.size()
		var e: Dictionary = C.EVENTS[day_idx]
		var factor: float = float(e.factors.get(id, 0.0))
		var wave1: float = 0.14 * sin(t_f * 0.83 + float(n) * 1.7)
		var wave2: float = 0.07 * sin(t_f * 0.37 + float(n) * 0.91)
		var base_price: float = float(catalog[id].base)
		return int(max(1, round(base_price * (1.0 + factor + wave1 + wave2))))
	
	var ask: int = value_func.call(step)
	var mult: float = 0.78 if kind == "raw" else 0.88
	var bid: int = int(max(1, floor(float(ask) * mult)))
	var previous: int = int(max(1, floor(float(value_func.call(step - 1)) * mult)))
	var change_val: int = int(round((float(bid) / float(previous) - 1.0) * 100.0))
	var next_val: float = float(step + 1) * C.QUOTE_INTERVAL - s.clock
	return { "ask": ask, "bid": bid, "change": change_val, "next": next_val }

static func new_relationships() -> Dictionary:
	var dict: Dictionary = {}
	for name: String in C.COMPANIES:
		dict[name] = { "score": 0, "delivered": 0, "missed": 0 }
	return dict

static func relationship(s: Dictionary, buyer: String) -> Dictionary:
	var key: String = buyer if C.COMPANIES.has(buyer) else "Nový odberateľ"
	return s.relationships[key]

static func company_terms(s: Dictionary, buyer: String) -> Dictionary:
	var score: int = int(relationship(s, buyer).score)
	var bonus: int = int(floor(float(score) * 0.3 + 0.5)) # JavaScript Math.round uses positive infinity for ties.
	var volume: float = 1.0 + float(score) / 50.0
	var label: String = "Strategický partner" if score >= 60 else ("Spoľahlivý dodávateľ" if score >= 20 else ("Rastúca dôvera" if score > 0 else ("Poškodený vzťah" if score <= -40 else ("Narušená dôvera" if score < 0 else "Nový vzťah"))))
	return { "score": score, "bonus": bonus, "volume": volume, "label": label }

static func make_offer(s: Dictionary, id: String, product: String, base_quantity: int, buyer: String) -> Dictionary:
	var terms: Dictionary = company_terms(s, buyer)
	var q: int = int(max(1, round(float(base_quantity) * maxf(0.5, float(terms.volume)))))
	var base_pay: int = contract_payout(product, q)
	var payout: int = int(max(1, round(float(base_pay) * (1.0 + float(terms.bonus) / 100.0))))
	return {
		"id": id,
		"product": product,
		"quantity": q,
		"payout": payout,
		"buyer": buyer,
		"status": "offer",
		"deadline": null,
		"offerDeadline": s.clock + C.OFFER_SECONDS,
		"acceptedAt": null,
		"bonus": terms.bonus
	}

static func expire_contracts(s: Dictionary) -> void:
	for c in s.contracts:
		if c.status == "offer" and s.clock >= float(c.offerDeadline) - C.EPS:
			c.status = "lapsed"
			log_msg(s, "Ponuka vypršala: " + c.buyer + " · bez postihu.", "contract")
		if c.status == "active" and s.clock >= float(c.deadline) - C.EPS:
			c.status = "expired"
			s.reputation = int(max(0, s.reputation - 1))
			var r: Dictionary = relationship(s, c.buyer)
			r.score = int(max(-100, r.score - 15))
			r.missed += 1
			log_msg(s, "Zmeškaný termín: " + c.buyer + " · vzťah −15, reputácia −1.", "warning")

static func offers(s: Dictionary) -> void:
	var ids: Array = []
	for uid in s.unlocked:
		var mapped: String = C.WASH.outputs.get(uid, uid)
		if not ids.has(mapped):
			ids.append(mapped)
	var num: int = day(s)
	var buyers: Array = C.COMPANIES.slice(0, 4)
	var active: Array = []
	for c in s.contracts:
		if c.status == "active" or (c.status == "offer" and float(c.offerDeadline) > s.clock):
			active.append(c)
	var fresh_offers: Array = []
	for i in range(3):
		var p: String = ids[(num - 1 + i) % ids.size()]
		var qty: int = 2 + (num + i) % 3
		var buyer: String = buyers[(num + i) % buyers.size()]
		fresh_offers.append(make_offer(s, "D" + str(num) + "-" + str(i), p, qty, buyer))
	s.contracts = active + fresh_offers

static func position_key(role: String, crew: int, slot: int = -1) -> String:
	return role + ":" + str(slot) + ":" + str(crew)

static func positions(s: Dictionary) -> Array:
	var rows: Array = []
	var roles = ["ladle", "furnace", "warehouse", "washer", "foreman", "operator"]
	for role in roles:
		var min_slot: int = 0 if role == "operator" else -1
		var max_slot: int = C.SLOTS if role == "operator" else 0
		for slot in range(min_slot, max_slot):
			if role == "operator" and s.machines[slot] == null:
				continue
			var max_crew: int = 2 if role == "foreman" else 3
			for crew in range(max_crew):
				var lbl: String = C.JOBS[role] + ((" " + str(slot + 1)) if slot >= 0 else "")
				var hrs: String = C.FOREMEN[crew].hours if role == "foreman" else C.CREWS[crew].hours
				rows.append({
					"key": position_key(role, crew, slot),
					"role": role,
					"crew": crew,
					"slot": slot,
					"label": lbl,
					"hours": hrs
				})
	return rows

static func employee(s: Dictionary, id: String) -> Variant:
	if not s.get("hr"):
		return null
	for e in s.hr.employees:
		if e.id == id:
			return e
	return null

static func assigned(s: Dictionary, key: String) -> Variant:
	if not s.get("hr"):
		return null
	for e in s.hr.employees:
		if e.active and e.position == key:
			return e
	return null

static func position_cycle(s: Dictionary, p: Dictionary) -> int:
	var dur: float = 90.0 if p.role == "foreman" else 60.0
	return int(floor((s.clock - 45.0 + C.EPS) / dur))

static func position_end(s: Dictionary, p: Dictionary) -> float:
	var dur: float = 90.0 if p.role == "foreman" else 60.0
	return float((position_cycle(s, p) + 1) * int(dur) + 45)

static func position_active(s: Dictionary, p: Dictionary) -> bool:
	return p.crew == foreman_shift(s) if p.role == "foreman" else p.crew == shift(s)

static func duty(s: Dictionary, role: String, slot: int = -1) -> Variant:
	if not s.get("hr"):
		return null
	var crw: int = foreman_shift(s) if role == "foreman" else shift(s)
	var key: String = position_key(role, crw, slot)
	var cover: Variant = null
	for c in s.hr.covers:
		if c.position == key and float(c.until) > s.clock + C.EPS:
			cover = c
			break
	var e: Variant = employee(s, cover.employeeId) if cover != null else assigned(s, key)
	if e == null or not e.active:
		return null
	if cover != null:
		return e
	var a: Variant = s.hr.attendance.get(key)
	if a != null and a.employeeId == e.id and not a.absent:
		return e
	return null

static func profile(e: Variant) -> Variant:
	if e == null:
		return null
	var app: int = e.get("appearance", 0)
	var base: Dictionary = C.FOREMEN[app] if e.role == "foreman" else (C.FURNACE_CREWS[e.crew] if e.role == "furnace" else (C.WAREHOUSE_CREWS[e.crew] if e.role == "warehouse" else C.CREWS[e.crew]))
	var res: Dictionary = base.duplicate(true)
	for k in e.keys():
		res[k] = e[k]
	res["job"] = C.JOBS[e.role] + ((" " + str(e.slot + 1)) if e.slot >= 0 else "")
	res["helmet"] = base.get("helmet", "#dcd5a0")
	return res

static func personnel_roll(s: Dictionary) -> float:
	var next_rng: int = (1664525 * int(s.hr.rng) + 1013904223) & 0xFFFFFFFF
	s.hr.rng = next_rng
	return float(next_rng) / 4294967296.0

static func has_defect(role: String) -> bool:
	return role != "warehouse" and role != "washer" and role != "foreman"

static func role_traits(role: String, person: Dictionary) -> Dictionary:
	var res: Dictionary = person.duplicate(true)
	if not has_defect(role):
		res.erase("defect")
	return res

static func candidate_salary(role: String, defect: Variant = null, absence: float = 0.0) -> float:
	var base: float = float(C.WAGES[role])
	var q_factor: float = (0.45 * (15.0 - float(defect)) / 14.0) if (has_defect(role) and defect != null) else 0.225
	var r_factor: float = 0.45 * (10.0 - absence) / 9.5
	var val: float = base * (0.65 + q_factor + r_factor)
	return round(val * 10.0) / 10.0

static func make_candidates(s: Dictionary, p: Dictionary) -> void:
	var n: int = 2 + int(floor(personnel_roll(s) * 4.0))
	var rows: Array = []
	for i in range(n):
		var defect: int = 1 + int(floor(personnel_roll(s) * 15.0))
		var absence: float = (1.0 + floor(personnel_roll(s) * 20.0)) / 2.0
		var sal: float = candidate_salary(p.role, defect, absence)
		var fn: String = C.CANDIDATE_NAMES[int(floor(personnel_roll(s) * float(C.CANDIDATE_NAMES.size())))]
		var sn: String = C.CANDIDATE_SURNAMES[int(floor(personnel_roll(s) * float(C.CANDIDATE_SURNAMES.size())))]
		var cand: Dictionary = {
			"id": "c" + str(s.hr.nextId),
			"name": fn + " " + sn,
			"absence": absence,
			"salary": sal
		}
		s.hr.nextId += 1
		if has_defect(p.role):
			cand["defect"] = defect
		rows.append(cand)
	s.hr.candidates[p.key] = rows

static func init_personnel(s: Dictionary, new_game: bool = false) -> void:
	s.hr = {
		"rng": (int(s.rng) ^ 0x5f3759df) & 0xFFFFFFFF,
		"nextId": 1,
		"employees": [],
		"candidates": {},
		"attendance": {},
		"covers": [],
		"lines": {},
		"startedAt": s.clock
	}
	for p in positions(s):
		var hired: bool = p.role == "foreman" if new_game else ((p.role != "operator" and p.role != "washer") or bool(s.operators[p.slot][p.crew]))
		if hired:
			var nm: String = ""
			if p.role == "operator":
				nm = C.OPERATORS[p.slot][p.crew]
			elif p.role == "foreman":
				nm = C.FOREMEN[p.crew].name
			elif p.role == "ladle":
				nm = C.CREWS[p.crew].name
			elif p.role == "furnace":
				nm = C.FURNACE_CREWS[p.crew].name
			else:
				nm = C.WAREHOUSE_CREWS[p.crew].name
			var e: Dictionary = {
				"id": "e" + str(s.hr.nextId),
				"position": p.key,
				"role": p.role,
				"crew": p.crew,
				"slot": p.slot,
				"name": nm,
				"salary": float(C.WAGES[p.role]),
				"absence": 2.5,
				"hiredAt": s.clock,
				"active": true,
				"appearance": p.crew if p.role == "foreman" else 0
			}
			s.hr.nextId += 1
			if has_defect(p.role):
				e["defect"] = 5
			s.hr.employees.append(e)
			if position_active(s, p):
				s.hr.attendance[p.key] = {
					"cycle": position_cycle(s, p),
					"employeeId": e.id,
					"absent": false
				}
		else:
			make_candidates(s, p)

	var remaining: float = float(s.payroll.accrued)
	for slot in range(C.SLOTS):
		for crew in range(3):
			var amount: float = float(s.payroll.operatorByCrew[slot][crew])
			amount = minf(remaining, maxf(0.0, amount))
			if amount > 0.0:
				var pos_k: String = position_key("operator", crew, slot)
				var emp_found: Variant = assigned(s, pos_k)
				var id_k: String = emp_found.id if emp_found != null else ("legacy-operator-" + str(slot) + "-" + str(crew))
				var nm: String = emp_found.name if emp_found != null else C.OPERATORS[slot][crew]
				s.hr.lines[id_k] = {
					"employeeId": id_k,
					"name": nm,
					"role": "operator",
					"slot": slot,
					"crew": crew,
					"normal": amount,
					"overtime": 0.0,
					"severance": 0.0
				}
				remaining -= amount

	for crew in range(2):
		var amount: float = float(s.payroll.foremenAccrued[crew])
		amount = minf(remaining, maxf(0.0, amount))
		if amount > 0.0:
			var pos_k: String = position_key("foreman", crew, -1)
			var emp_found: Variant = assigned(s, pos_k)
			var id_k: String = emp_found.id if emp_found != null else ("legacy-foreman--1-" + str(crew))
			var nm: String = emp_found.name if emp_found != null else C.FOREMEN[crew].name
			s.hr.lines[id_k] = {
				"employeeId": id_k,
				"name": nm,
				"role": "foreman",
				"slot": -1,
				"crew": crew,
				"normal": amount,
				"overtime": 0.0,
				"severance": 0.0
			}
			remaining -= amount

	if remaining > 0.0:
		s.hr.lines["legacy"] = {
			"employeeId": "legacy",
			"name": "Mzdy prenesené z pôvodného rozpisu",
			"normal": remaining,
			"overtime": 0.0,
			"severance": 0.0
		}

static func sync_personnel(s: Dictionary) -> void:
	if not s.get("hr"):
		return
	var changed: bool = false
	var valid_covers: Array = []
	for c in s.hr.covers:
		var emp: Variant = employee(s, c.employeeId)
		if float(c.until) > s.clock + C.EPS and emp != null and emp.active:
			valid_covers.append(c)
	s.hr.covers = valid_covers

	for p in positions(s):
		var e: Variant = assigned(s, p.key)
		if e == null and not s.hr.candidates.has(p.key):
			make_candidates(s, p)
		if not position_active(s, p) or e == null:
			continue
		var cycle: int = position_cycle(s, p)
		var a: Variant = s.hr.attendance.get(p.key)
		if a != null and a.cycle == cycle and a.employeeId == e.id:
			continue
		var absent: bool = personnel_roll(s) < float(e.absence) / 100.0
		s.hr.attendance[p.key] = {
			"cycle": cycle,
			"employeeId": e.id,
			"absent": absent
		}
		changed = true
		if absent:
			log_msg(s, e.name + " neprišiel na smenu · " + p.label + ". V Kancelárii zavolaj zastúpenie.", "warning")
	if changed:
		s.revision += 1

static func busy_employee(s: Dictionary, id: String) -> bool:
	if s.delivery != null and (s.delivery.employeeId == id or s.delivery.furnaceId == id):
		return true
	for m in s.machines:
		if m != null:
			if m.state == "working" and m.employeeId == id:
				return true
			if m.state == "unloading" and m.unloadEmployeeId == id:
				return true
	return false

static func working_employees(s: Dictionary) -> Array:
	var result_map: Dictionary = {}
	for p in positions(s):
		if not position_active(s, p):
			continue
		var e: Variant = duty(s, p.role, p.slot)
		if e != null:
			result_map[e.id] = e
	if s.delivery != null:
		for id in [s.delivery.employeeId, s.delivery.furnaceId]:
			if id != null:
				var e: Variant = employee(s, id)
				if e != null and e.active:
					result_map[e.id] = e
	for m in s.machines:
		if m != null and m.state == "unloading" and m.unloadEmployeeId != null:
			var e: Variant = employee(s, m.unloadEmployeeId)
			if e != null and e.active:
				result_map[e.id] = e
	return result_map.values()

static func regular_shift_pay(e: Dictionary) -> float:
	var mult: float = 1.0
	if e.role == "foreman":
		mult = 1.5 if e.crew == 0 else 2.0
	elif e.crew == 2:
		mult = 1.5
	return float(e.salary) * mult

static func weekly_pay(e: Dictionary) -> float:
	return regular_shift_pay(e) * 7.0

static func tenure(s: Dictionary, e: Dictionary) -> int:
	return int(max(0, floor((s.clock - float(e.hiredAt) + C.EPS) / C.MONTH)))

static func severance(s: Dictionary, e: Dictionary) -> int:
	var t: int = tenure(s, e)
	var mults = [0, 1, 2, 4]
	var m_idx: int = min(3, t)
	return int(round(weekly_pay(e) * float(mults[m_idx])))

static func earning_line(s: Dictionary, e: Dictionary) -> Dictionary:
	if not s.hr.lines.has(e.id):
		s.hr.lines[e.id] = {
			"employeeId": e.id,
			"name": e.name,
			"normal": 0.0,
			"overtime": 0.0,
			"severance": 0.0
		}
	return s.hr.lines[e.id]

static func own_duty(s: Dictionary, e: Dictionary) -> bool:
	return e.crew == foreman_shift(s) if e.role == "foreman" else e.crew == shift(s)

static func accrue_personnel(s: Dictionary, step: float) -> void:
	if s.payroll.debt > 0:
		return
	for e in working_employees(s):
		var has_cover: bool = false
		for c in s.hr.covers:
			if c.employeeId == e.id and float(c.until) > s.clock + C.EPS:
				has_cover = true
				break
		var overtime: bool = has_cover or not own_duty(s, e)
		var rate: float = (1.5 if shift(s) == 2 else 1.0) * (1.5 if overtime else 1.0)
		var amount: float = float(e.salary) * step / 60.0 * rate
		var line_dict: Dictionary = earning_line(s, e)
		line_dict["overtime" if overtime else "normal"] += amount
		s.payroll.accrued += amount
		if e.role == "operator":
			s.payroll.operatorAccrued[e.slot] += amount
			s.payroll.operatorByCrew[e.slot][e.crew] += amount
		if e.role == "foreman":
			s.payroll.foremenAccrued[e.crew] += amount

static func pay_personnel(s: Dictionary, crew: int) -> void:
	var due: int = int(round(float(s.payroll.accrued) + C.EPS))
	var employees: Array = []
	for l in s.hr.lines.values():
		employees.append(l.duplicate(true))
	var extra: int = 0
	for l in employees:
		extra += int(l.severance)
	var foremen: Array = s.payroll.foremenAccrued.duplicate(true)
	var operators: Array = []
	for l in employees:
		var emp: Variant = employee(s, l.employeeId)
		if emp == null:
			emp = l
		if emp.get("role") == "operator":
			operators.append({
				"slot": emp.slot,
				"crew": emp.crew,
				"name": l.name,
				"amount": l.normal + l.overtime
			})
	s.hr.lines = {}
	s.payroll.accrued = 0.0
	s.payroll.operatorAccrued = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	s.payroll.operatorByCrew = [
		[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0],
		[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]
	]
	s.payroll.foremenAccrued = [0.0, 0.0]
	if due == 0:
		return
	var paid: int = int(min(s.money, due))
	s.money -= paid
	s.payroll.paid += paid
	s.payroll.debt += due - paid
	s.payroll.history.insert(0, {
		"clock": s.clock,
		"crew": crew,
		"due": due,
		"paid": paid,
		"weekly": true,
		"team": true,
		"operators": operators,
		"foremen": foremen,
		"employees": employees,
		"severance": extra
	})
	if s.payroll.history.size() > 12:
		s.payroll.history.resize(12)
	var log_t: String = "Týždenná výplata · " + str(due) + " ₵ vrátane nadčasov a " + str(extra) + " ₵ odstupného · uhradené " + str(paid) + " ₵" + ((" · nedoplatok " + str(due - paid) + " ₵") if paid < due else "")
	log_msg(s, log_t, "warning" if paid < due else "wage")

static func overtime_choices(s: Dictionary, key: String) -> Array:
	var pos_match: Variant = null
	for p in positions(s):
		if p.key == key:
			pos_match = p
			break
	if pos_match == null or not position_active(s, pos_match) or duty(s, pos_match.role, pos_match.slot) != null:
		return []
	var res: Array = []
	for e in s.hr.employees:
		if e.active and e.role == pos_match.role and not own_duty(s, e) and not busy_employee(s, e.id):
			var covered: bool = false
			for c in s.hr.covers:
				if c.employeeId == e.id and float(c.until) > s.clock + C.EPS:
					covered = true
					break
			if not covered:
				res.append(e)
	return res

static func personnel_action(s: Dictionary, c: Dictionary) -> Dictionary:
	sync_personnel(s)
	var act: String = c.get("action", "")
	if act == "hire":
		var target_pos: String = str(c.get("position", ""))
		var pos_match: Variant = null
		for p in positions(s):
			if p.key == target_pos:
				pos_match = p
				break
		if pos_match == null or assigned(s, target_pos) != null:
			return fail_res("Vyber voľnú pozíciu v Kancelárii.")
		var candidates_list: Array = s.hr.candidates.get(target_pos, [])
		var cand_id: String = str(c.get("candidateId", ""))
		var cand: Variant = null
		for cd in candidates_list:
			if cd.id == cand_id:
				cand = cd
				break
		if cand == null:
			return fail_res("Vyber konkrétneho uchádzača z ponuky.")
		var e: Dictionary = cand.duplicate(true)
		e["id"] = "e" + str(s.hr.nextId)
		s.hr.nextId += 1
		e["position"] = pos_match.key
		e["role"] = pos_match.role
		e["crew"] = pos_match.crew
		e["slot"] = pos_match.slot
		e["hiredAt"] = s.clock
		e["active"] = true
		e["appearance"] = pos_match.crew if pos_match.role == "foreman" else 0
		s.hr.employees.append(e)
		var remaining_covers: Array = []
		for o in s.hr.covers:
			if o.position != pos_match.key:
				remaining_covers.append(o)
		s.hr.covers = remaining_covers
		s.hr.candidates.erase(pos_match.key)
		if pos_match.role == "operator":
			s.operators[pos_match.slot][pos_match.crew] = true
		if position_active(s, pos_match):
			s.hr.attendance[pos_match.key] = {
				"cycle": position_cycle(s, pos_match),
				"employeeId": e.id,
				"absent": false
			}
		log_msg(s, "Prijatý " + e.name + " · " + pos_match.label + " · " + str(regular_shift_pay(e)) + " ₵ / smena.", "crew")
		return ok_res("Prijatý " + e.name + ". Mzda nabieha iba za odpracovaný čas.")

	elif act == "dismiss":
		var emp_id: String = str(c.get("employeeId", ""))
		var e: Variant = employee(s, emp_id)
		if e == null or not e.active:
			return fail_res("Pracovník už nie je zamestnaný.")
		if busy_employee(s, e.id):
			return fail_res("Počkaj na dokončenie rozpracovaného kusu alebo panvy.")
		var extra: int = severance(s, e)
		var l: Dictionary = earning_line(s, e)
		l.severance += extra
		s.payroll.accrued += extra
		e.active = false
		e.dismissedAt = s.clock
		var rem_covers: Array = []
		for o in s.hr.covers:
			if o.employeeId != e.id:
				rem_covers.append(o)
		s.hr.covers = rem_covers
		if e.role == "operator":
			s.operators[e.slot][e.crew] = false
		var pos_match: Variant = null
		for p in positions(s):
			if p.key == e.position:
				pos_match = p
				break
		if pos_match != null:
			make_candidates(s, pos_match)
		log_msg(s, "Prepustený " + e.name + " · odstupné " + str(extra) + " ₵ k najbližšej výplate. Zarobená mzda zostáva zachovaná.", "wage")
		return ok_res("Pracovný pomer ukončený. Odstupné " + str(extra) + " ₵ sa pripočíta k týždennej výplate.")

	elif act == "overtime":
		var target_pos: String = str(c.get("position", ""))
		var emp_id: String = str(c.get("employeeId", ""))
		var choices: Array = overtime_choices(s, target_pos)
		var e: Variant = null
		for cd in choices:
			if cd.id == emp_id:
				e = cd
				break
		var pos_match: Variant = null
		for p in positions(s):
			if p.key == target_pos:
				pos_match = p
				break
		if e == null or pos_match == null:
			return fail_res("Tento pracovník nemôže zastúpiť danú smenu.")
		s.hr.covers.append({
			"position": pos_match.key,
			"employeeId": e.id,
			"until": position_end(s, pos_match),
			"startedAt": s.clock
		})
		log_msg(s, e.name + " nastupuje na nadčas · " + pos_match.label + " · sadzba +50 % (aj k nočnej sadzbe).", "crew")
		return ok_res("Zastúpenie do konca tejto smeny. Platí sa odpracovaný čas s príplatkom 50 %.")

	return fail_res("Neznáma personálna akcia.")

static func total_failure_risk(s: Dictionary, m: Variant, slot: int) -> float:
	var base: float = failure_risk(m)
	if base > 0.0:
		var d_op: Variant = duty(s, "operator", slot)
		var op_defect: float = float(d_op.defect) if (d_op != null and d_op.has("defect")) else 0.0
		return minf(1.0, base + op_defect / 100.0)
	return 0.0

static func operator(s: Dictionary, slot: int, crew: Variant = null) -> Variant:
	var crw: int = int(crew) if crew != null else shift(s)
	if s.get("hr"):
		var key: String = position_key("operator", crw, slot)
		var emp: Variant = duty(s, "operator", slot) if crw == shift(s) else assigned(s, key)
		return profile(emp)
	return null

static func consume_goods(s: Dictionary, id: String, quantity: int) -> void:
	s.goods[id] -= quantity
	var remaining: int = quantity
	for pallet in s.pallets:
		var n: int = int(min(pallet.get(id, 0), remaining))
		pallet[id] -= n
		remaining -= n
		if remaining == 0:
			break

static func new_payroll() -> Dictionary:
	return {
		"accrued": 0.0,
		"foremenAccrued": [0.0, 0.0],
		"operatorAccrued": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
		"operatorByCrew": [
			[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0],
			[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]
		],
		"paid": 0,
		"debt": 0,
		"history": []
	}

static func fresh() -> Dictionary:
	var s: Dictionary = {
		"version": 14,
		"cncOwned": [false, false, false, false, false, false, false],
		"cncPower": [false, false, false, false, false, false, false],
		"operators": empty_staff(),
		"pallets": empty_pallets(),
		"relationships": new_relationships(),
		"washer": new_washer(),
		"rng": 12345678,
		"scrapped": 0,
		"money": 1000,
		"sold": 0,
		"made": 0,
		"revenue": 0,
		"reputation": 0,
		"completedContracts": 0,
		"clock": 45.0,
		"selected": 0,
		"queue": [],
		"delivery": null,
		"machines": [machine(), null, null, null, null, null],
		"raw": { "iron": 60, "steel": 0, "copper": 0, "tin": 0, "zinc": 20 },
		"incoming": empty_raw(),
		"bins": empty_raw(),
		"binUnlocked": { "iron": true, "zinc": true, "steel": false, "copper": false, "tin": false },
		"payroll": new_payroll(),
		"stockMove": null,
		"goods": empty_goods(),
		"storage": { "raw": 0, "goods": 0 },
		"unlocked": ["iron_pipe", "ring"],
		"logistics": 0,
		"limits": [],
		"contracts": [],
		"ledger": [],
		"milestones": [],
		"nextId": 1,
		"revision": 0,
		"lastShift": 0,
		"previousShift": 2,
		"shiftChangedAt": 45.0,
		"shiftChanges": 0
	}
	init_personnel(s, true)
	offers(s)
	log_msg(s, "Dielňa otvorená. V Kancelárii prijmi panvára, taviča, skladníka, obsluhu odstredivky a pieskovača na každú smenu. Majstri Mišo a Miro sú už zamestnaní. V sklade máš 60 kg železa a 20 kg zinku, ostatné suroviny treba nakúpiť.", "stock")
	return s

static func can_cast(s: Dictionary, i: int) -> String:
	var m: Variant = s.machines[i]
	if m == null:
		return "Najprv postav odstredivku."
	if m.state != "idle":
		return "Stroj už pracuje."
	if s.get("hr") and duty(s, "ladle") == null:
		return "Chýba panvár. V Kancelárii obsadíš smenu alebo zavoláš nadčas."
	if s.get("hr") and duty(s, "furnace") == null:
		return "Chýba tavič. Otvor Kanceláriu."
	if s.get("hr") and duty(s, "foreman") == null:
		return "Chýba majster v službe. Otvor Kanceláriu."
	if operator(s, i) == null:
		return "Chýba obsluha tejto odstredivky na aktuálnej smene. Prijmi zamestnanca."
	if s.payroll.debt > 0:
		return "Dlžné mzdy: " + str(s.payroll.debt) + " ₵. Vyplať zamestnancov, aby spustili novú dávku."
	if not s.unlocked.has(m.product):
		return "Najprv odomkni výrobný postup."
	if used(s, "goods") + reserved_output(s) >= capacity(s, "goods"):
		return "Sklad výrobkov je plný. Predaj zásoby alebo zväčši sklad."
	var missing: Array = []
	var recipe: Dictionary = C.PRODUCTS[m.product].recipe
	for mid: String in recipe.keys():
		var req: int = int(recipe[mid])
		var cur: int = int(s.raw[mid])
		if cur < req:
			var inc: int = int(s.incoming[mid])
			var txt: String = C.MATERIALS[mid].short + " " + str(req - cur) + " kg" + ((" (na rampe " + str(inc) + " kg)") if inc > 0 else "")
			missing.append(txt)
	if missing.size() > 0:
		return "Chýba: " + ", ".join(missing) + "."
	return ""

static func begin_cast(s: Dictionary, i: int) -> void:
	var m: Dictionary = s.machines[i]
	var p: Dictionary = C.PRODUCTS[m.product]
	for mid: String in p.recipe.keys():
		s.raw[mid] -= int(p.recipe[mid])
	m.state = "working"
	m.elapsed = 0.0
	m.served = false
	m.failedElapsed = 0.0
	var op: Variant = duty(s, "operator", i)
	m.employeeId = op.id if op != null else null
	m.batchRisk = total_failure_risk(s, m, i)
	m.reject = m.batchRisk > 0.0 and roll(s) < m.batchRisk
	s.queue.append(i)
	var recipe_str: Array = []
	for mid in p.recipe.keys():
		recipe_str.append(str(p.recipe[mid]) + " kg " + C.MATERIALS[mid].short.to_lower())
	log_msg(s, "Stroj " + str(i + 1) + ": " + p.name + " · vsádzka " + " + ".join(recipe_str), "production")

static func collect(s: Dictionary, i: int) -> Dictionary:
	var m: Variant = s.machines[i]
	if m == null or m.state != "ready":
		return fail_res("Výrobok ešte nie je pripravený na vyloženie.")
	if operator(s, i) == null:
		return fail_res("Na vyloženie chýba obsluha aktuálnej smeny.")
	if used(s, "goods") + reserved_output(s) > capacity(s, "goods"):
		return fail_res("Sklad výrobkov je plný.")
	m.state = "unloading"
	m.unloadElapsed = 0.0
	m.unloadCrew = shift(s)
	var op: Variant = operator(s, i)
	m.unloadEmployeeId = op.id if op != null else null
	var op_name: String = op.name if op != null else "Obsluha"
	log_msg(s, op_name + " vyberá výrobok a odnáša ho na paletu pri stroji " + str(i + 1) + ".", "stock")
	return ok_res("Obsluha odnesie výrobok na paletu za 4 sekundy.")

static func act(s: Dictionary, i: int, action: String, options: Dictionary = {}) -> Dictionary:
	return act_machine(s, i, action, options)

static func act_machine(s: Dictionary, i: int, action: String, options: Dictionary = {}) -> Dictionary:
	if i < 0 or i >= C.SLOTS:
		return fail_res("Neplatné stanovište.")
	var m: Variant = s.machines[i]
	if action == "buy":
		if m != null:
			return fail_res("Tu už stojí odstredivka.")
		var cost: int = price(s)
		if s.money < cost + 50:
			return fail_res("Potrebuješ " + str(cost + 50) + " ₵ vrátane 50 ₵ rezervy na materiál.")
		s.money -= cost
		s.machines[i] = machine()
		sync_personnel(s)
		s.selected = i
		log_msg(s, "Nová odstredivka na stanovišti " + str(i + 1) + " · −" + str(cost) + " ₵", "upgrade")
		return ok_res("Odstredivka kúpená. Pred výrobou prijmi obsluhu na svoju smenu.")
	if m == null:
		return fail_res("Najprv postav odstredivku.")
	if action == "configure":
		if m.state != "idle":
			return fail_res("Produkt môžeš meniť iba na voľnom stroji.")
		var p_id: String = options.get("product", "")
		if not s.unlocked.has(p_id) or C.PRODUCTS.get(p_id, {}).get("finished", false):
			return fail_res("Výrobný postup ešte nie je odomknutý.")
		m.product = p_id
		s.revision += 1
		return ok_res("Nastavené: " + C.PRODUCTS[m.product].name + ".")
	if action == "auto":
		if not (options.get("enabled") is bool):
			return fail_res("Neplatné nastavenie série.")
		m.auto = options.enabled
		s.revision += 1
		return ok_res("Séria zapnutá. Stroj vyrába, kým má obsluhu aktuálnej smeny, materiál a miesto." if m.auto else "Séria vypnutá. Rozpracovaný kus sa dokončí.")
	if action == "cast":
		var err: String = can_cast(s, i)
		if not err.is_empty():
			return fail_res(err)
		begin_cast(s, i)
		return ok_res("Vsádzka odobratá zo skladu. Rúra sa roztáča.")
	if action == "collect":
		return collect(s, i)
	if action == "sell":
		return fail_res("Výrobok musí obsluha najprv odniesť na paletu. Rúry potom vyčisti v pieskovači; predávaj cez burzu.")
	if action == "upgrade":
		if m.state != "idle":
			return fail_res("Najprv uvoľni stroj.")
		if m.level >= 3:
			return fail_res("Stroj má najvyššiu úroveň.")
		var cost: int = upgrade_price(m)
		if s.money < cost + 50:
			return fail_res("Nechaj si 50 ₵ na materiál. Potrebuješ " + str(cost + 50) + " ₵.")
		s.money -= cost
		m.level += 1
		log_msg(s, "Stroj " + str(i + 1) + " vylepšený na MK " + str(m.level) + " · −" + str(cost) + " ₵", "upgrade")
		return ok_res("Rýchlejšia výroba je pripravená.")
	return fail_res("Neznáma akcia.")

static func trade(s: Dictionary, item: String, side: String, quantity: int) -> Dictionary:
	if quantity < 1 or quantity > 1000 or (side != "buy" and side != "sell"):
		return fail_res("Zadaj celé množstvo od 1 do 1 000.")
	var q: Variant = quote(s, item)
	if q == null:
		return fail_res("Neznáma položka.")
	var parts: PackedStringArray = item.split(":")
	var kind: String = parts[0]
	var id: String = parts[1]
	var name: String = C.MATERIALS[id].name if kind == "raw" else C.PRODUCTS[id].name
	if kind == "goods" and side == "buy":
		return fail_res("Výrobky sa nedajú kupovať. Vyrob ich vo vlastnej zlievarni.")
	if kind == "goods" and not saleable(id):
		return fail_res("Výrobok najprv vyčisti v pieskovači. Predávať možno iba očistené odliatky.")
	if side == "sell" and s.get("hr") and duty(s, "warehouse") == null:
		return fail_res("Na expedíciu chýba skladník. Otvor Kanceláriu.")
	if side == "buy":
		var total: int = int(q.ask) * quantity
		var target: String = "incoming" if kind == "raw" else "goods"
		if s.money < total:
			return fail_res("Na nákup potrebuješ " + str(total) + " ₵.")
		var extra_res: int = reserved_output(s) if kind == "goods" else 0
		if used(s, target) + extra_res + quantity > capacity(s, target):
			return fail_res("Príjmová rampa je plná. Najprv uskladni dodávky." if kind == "raw" else "Nie je dosť miesta v sklade.")
		s.money -= total
		s[target][id] += quantity
		log_msg(s, "Nákup: " + str(quantity) + (" kg " if kind == "raw" else " ks ") + name + " · −" + str(total) + " ₵" + ((" · dodané na rampu") if kind == "raw" else ""), "purchase")
		return ok_res(("Dodané na rampu. Otvor sklad a uskladni " + str(quantity) + " kg.") if kind == "raw" else ("Nakúpené za " + str(total) + " ₵."))

	var stock: int = available(s, id) if kind == "goods" else int(s.raw[id]) + int(s.incoming[id])
	if stock < quantity:
		return fail_res("Nemáš dostatok voľných zásob. Tovar v pokynoch je rezervovaný.")
	var total_bid: int = int(q.bid) * quantity
	if kind == "raw":
		var from_dock: int = int(min(quantity, s.incoming[id]))
		s.incoming[id] -= from_dock
		s.raw[id] -= (quantity - from_dock)
	else:
		consume_goods(s, id, quantity)
	s.money += total_bid
	s.revenue += total_bid
	if kind == "goods":
		s.sold += quantity
	log_msg(s, "Predaj: " + str(quantity) + (" kg " if kind == "raw" else " ks ") + name + " · +" + str(total_bid) + " ₵", "sale")
	return ok_res("Predané za " + str(total_bid) + " ₵.")

static func limit_sell(s: Dictionary, product: String, quantity: int, min_price: int) -> Dictionary:
	if not saleable(product) or quantity < 1 or quantity > 1000 or min_price < 1 or min_price > 100000:
		return fail_res("Skontroluj produkt, množstvo a minimálnu cenu.")
	if s.limits.size() >= 5:
		return fail_res("Môžeš mať najviac 5 predajných pokynov.")
	if available(s, product) < quantity:
		return fail_res("Nemáš dosť nerezervovaných výrobkov.")
	var order: Dictionary = {
		"id": s.nextId,
		"product": product,
		"quantity": quantity,
		"minPrice": min_price,
		"created": s.clock
	}
	s.nextId += 1
	s.limits.append(order)
	log_msg(s, "Rezervované " + str(quantity) + " ks: " + C.PRODUCTS[product].name + " · predaj od " + str(min_price) + " ₵/ks", "order")
	return ok_res("Pokyn čaká na najbližšiu aktualizáciu burzy.")

static func check_orders(s: Dictionary) -> void:
	if s.get("hr") and duty(s, "warehouse") == null:
		return
	var orders_copy: Array = s.limits.duplicate(true)
	for order in orders_copy:
		if not saleable(order.product):
			s.limits = s.limits.filter(func(o): return o.id != order.id)
			continue
		var q: Variant = quote(s, "goods:" + order.product)
		if q != null and int(q.bid) >= int(order.minPrice) and int(s.goods[order.product]) >= int(order.quantity):
			consume_goods(s, order.product, order.quantity)
			var amount: int = int(order.quantity) * int(q.bid)
			s.money += amount
			s.revenue += amount
			s.sold += int(order.quantity)
			s.limits = s.limits.filter(func(o): return o.id != order.id)
			log_msg(s, "Pokyn vykonaný: " + str(order.quantity) + " ks " + C.PRODUCTS[order.product].name + " za " + str(q.bid) + " ₵/ks · +" + str(amount) + " ₵", "sale")

static func contract_action(s: Dictionary, id: String, action: String) -> Dictionary:
	var c_match: Variant = null
	for c in s.contracts:
		if c.id == id:
			c_match = c
			break
	if c_match == null:
		return fail_res("Zákazka už nie je dostupná.")
	if not saleable(c_match.product):
		return fail_res("Do zákaziek možno dodávať iba očistené výrobky.")

	if action == "accept":
		if c_match.status != "offer":
			return fail_res("Ponuka už nie je dostupná.")
		if s.clock >= float(c_match.offerDeadline) - C.EPS:
			expire_contracts(s)
			return fail_res("Lehota na prijatie ponuky uplynula.")
		var active_count: int = 0
		for c in s.contracts:
			if c.status == "active":
				active_count += 1
		if active_count >= 2:
			return fail_res("Naraz môžeš prijať 2 zákazky.")
		c_match.status = "active"
		c_match.acceptedAt = s.clock
		c_match.deadline = s.clock + C.DELIVERY_SECONDS
		log_msg(s, "Prijatá zákazka: " + c_match.buyer + " · " + str(c_match.quantity) + " ks " + C.PRODUCTS[c_match.product].name, "contract")
		return ok_res("Zákazka prijatá. Máš 18 herných hodín (135 sekúnd).")

	elif action == "fulfill":
		if s.get("hr") and duty(s, "warehouse") == null:
			return fail_res("Na expedíciu zákazky chýba skladník. Otvor Kanceláriu.")
		if c_match.status != "active" or s.clock >= float(c_match.deadline):
			return fail_res("Zákazka nie je aktívna.")
		if available(s, c_match.product) < int(c_match.quantity):
			return fail_res("Chýbajú voľné výrobky. Rezervácie na burze sa sem nezapočítavajú.")
		consume_goods(s, c_match.product, int(c_match.quantity))
		s.money += int(c_match.payout)
		s.revenue += int(c_match.payout)
		s.sold += int(c_match.quantity)
		s.reputation += 2
		s.completedContracts += 1
		c_match.status = "done"
		var r: Dictionary = relationship(s, c_match.buyer)
		r.score = int(min(100, r.score + 10))
		r.delivered += 1
		log_msg(s, "Zákazka splnená: " + c_match.buyer + " · +" + str(c_match.payout) + " ₵ · reputácia +2 · vzťah s firmou +10", "contract")
		return ok_res("Zákazka splnená! +" + str(c_match.payout) + " ₵, reputácia +2, vzťah s firmou +10.")

	return fail_res("Neplatná akcia zákazky.")

static func expand(s: Dictionary, kind: String) -> Dictionary:
	if kind != "raw" and kind != "goods":
		return fail_res("Neznámy sklad.")
	if s.storage[kind] >= 5:
		return fail_res("Sklad má maximálnu kapacitu.")
	var mult: int = 260 if kind == "raw" else 220
	var cost: int = mult * (int(s.storage[kind]) + 1)
	if s.money < cost + 50:
		return fail_res("Potrebuješ " + str(cost + 50) + " ₵ vrátane rezervy.")
	s.money -= cost
	s.storage[kind] += 1
	log_msg(s, "Rozšírené " + ("príjmové miesto" if kind == "raw" else "miesto pre výrobky") + " · −" + str(cost) + " ₵", "upgrade")
	var unit: String = "kg" if kind == "raw" else "ks"
	var cap_id: String = "incoming" if kind == "raw" else kind
	return ok_res("Kapacita je teraz " + str(capacity(s, cap_id)) + " " + unit + ".")

static func store_material(s: Dictionary, id: String, quantity: int) -> Dictionary:
	if s.get("hr") and duty(s, "warehouse") == null:
		return fail_res("Chýba skladník. V Kancelárii zavolaj zastúpenie.")
	if not C.MATERIALS.has(id) or quantity <= 0:
		return fail_res("Vyber surovinu a celé kladné množstvo.")
	if not bin_open(s, id):
		return fail_res("Najprv odomkni tento sklad za " + str(C.BIN_UNLOCK[id]) + " ₵.")
	if s.incoming[id] < quantity:
		return fail_res("Na rampe nie je dosť tejto suroviny.")
	if s.raw[id] + quantity > bin_capacity(s, id):
		return fail_res("Tento zásobník je plný. Vylepši ho alebo spotrebuj zásoby.")
	s.incoming[id] -= quantity
	s.raw[id] += quantity
	s.stockMove = { "material": id, "quantity": quantity, "at": s.clock }
	log_msg(s, "Uskladnené: " + str(quantity) + " kg " + C.MATERIALS[id].short + " · rampa → zásobník", "stock")
	return ok_res("Uskladnené. " + C.MATERIALS[id].short + " môže ísť do výroby.")

static func expand_bin(s: Dictionary, id: String) -> Dictionary:
	if not C.MATERIALS.has(id):
		return fail_res("Neznámy zásobník.")
	if s.bins[id] >= 8:
		return fail_res("Zásobník má maximálnu kapacitu.")
	if not bin_open(s, id):
		var cost_unl: int = int(C.BIN_UNLOCK[id])
		if s.money < cost_unl:
			return fail_res("Odomknutie stojí " + str(cost_unl) + " ₵.")
		s.money -= cost_unl
		s.binUnlocked[id] = true
		log_msg(s, "Odomknutý sklad: " + C.MATERIALS[id].name + " · −" + str(cost_unl) + " ₵", "upgrade")
		return ok_res("Sklad odomknutý. Teraz sem môžeš ukladať suroviny.")
	var cost: int = bin_upgrade_price(s, id)
	if s.money < cost + 50:
		return fail_res("Potrebuješ " + str(cost + 50) + " ₵ vrátane rezervy.")
	s.money -= cost
	s.bins[id] += 1
	log_msg(s, "Zásobník " + C.MATERIALS[id].short + " rozšírený na " + str(bin_capacity(s, id)) + " kg · −" + str(cost) + " ₵", "upgrade")
	return ok_res("Zásobník má teraz " + str(bin_capacity(s, id)) + " kg.")

static func pay_debt(s: Dictionary) -> Dictionary:
	if s.payroll.debt <= 0:
		return fail_res("Všetky splatné mzdy sú vyplatené.")
	if s.money <= 0:
		return fail_res("Najprv predaj zásoby alebo dokončené výrobky.")
	var paid: int = int(min(s.money, s.payroll.debt))
	s.money -= paid
	s.payroll.debt -= paid
	s.payroll.paid += paid
	log_msg(s, "Doplatené mzdy · −" + str(paid) + " ₵" + ((" · zostáva " + str(s.payroll.debt) + " ₵") if s.payroll.debt > 0 else ""), "wage")
	return ok_res(("Uhradené " + str(paid) + " ₵. Zostáva " + str(s.payroll.debt) + " ₵.") if s.payroll.debt > 0 else "Mzdy vyplatené. Výroba môže pokračovať.")

static func unlock_recipe(s: Dictionary, id: String) -> Dictionary:
	if not C.PRODUCTS.has(id):
		return fail_res("Neznámy produkt.")
	var p: Dictionary = C.PRODUCTS[id]
	if p.finished:
		return fail_res("Tento výrobok vzniká čistením v hale Pieskovač.")
	if s.unlocked.has(id):
		return fail_res("Tento výrobok už vyrábaš.")
	if s.money < int(p.unlock) + 50:
		return fail_res("Potrebuješ " + str(int(p.unlock) + 50) + " ₵ vrátane rezervy.")
	s.money -= int(p.unlock)
	s.unlocked.append(id)
	log_msg(s, "Nový výrobný postup: " + p.name + " · −" + str(p.unlock) + " ₵", "upgrade")
	s.contracts.append(make_offer(s, "R" + str(s.nextId), C.WASH.outputs.get(id, id), 2, "Nový odberateľ"))
	s.nextId += 1
	return ok_res("Odomknuté: " + p.name + ". Vyber produkt na voľnom stroji.")

static func progress_val(s: Dictionary, g: Dictionary) -> int:
	if g.id == "machines":
		return occupied(s)
	return int(s.get(g.field, 0))

static func milestones(s: Dictionary) -> void:
	for g in C.GOALS:
		if not s.milestones.has(g.id) and progress_val(s, g) >= int(g.target):
			s.milestones.append(g.id)
			s.money += int(g.reward)
			log_msg(s, "Míľnik: " + g.name + " · odmena +" + str(g.reward) + " ₵", "reward")

static func washer_running(s: Dictionary) -> bool:
	return s.washer.active != null and duty(s, "washer") != null and s.payroll.debt == 0

static func cnc_price(i: int) -> Variant:
	if i >= 0 and i < 6:
		return 500 + i * 250
	return null

static func cnc_action(s: Dictionary, c: Dictionary) -> Dictionary:
	var i: int = int(c.get("slot", -1))
	if i < 0 or i > 6:
		return fail_res("Neplatný CNC stroj.")
	if i == 6:
		return fail_res("AMADA je zatiaľ zamknutá.")
	var act: String = c.get("action", "")
	if act == "buy":
		if s.cncOwned[i]:
			return fail_res("Tento CNC už vlastníš.")
		var cost: int = int(cnc_price(i))
		if s.money < cost:
			return fail_res("Na tento stroj potrebuješ " + str(cost) + " ₵.")
		s.money -= cost
		s.cncOwned[i] = true
		log_msg(s, "Kúpený CNC " + str(i + 1) + " · −" + str(cost) + " ₵. Rezanie zatiaľ nie je aktívne.", "upgrade")
		return ok_res("CNC " + str(i + 1) + " je kúpený. Výrobu zapojíme neskôr.")
	elif act == "toggle":
		if not s.cncOwned[i]:
			return fail_res("Najprv kúp tento CNC.")
		s.cncPower[i] = not s.cncPower[i]
		return ok_res("Signalizácia zapnutá. Rezanie zatiaľ nie je aktívne." if s.cncPower[i] else "Stroj vypnutý.")
	return fail_res("Neznáma akcia CNC.")

static func can_wash(s: Dictionary) -> String:
	var w: Dictionary = s.washer
	if duty(s, "washer") == null:
		return "Pieskovaču chýba obsluha na aktuálnej smene. Prijmi ju v Kancelárii alebo zavolaj nadčas."
	if s.get("hr") and duty(s, "warehouse") == null:
		return "Na naloženie výrobku chýba skladník. Otvor Kanceláriu."
	if w.active != null:
		return "Stroj práve čistí výrobok."
	if s.payroll.debt > 0:
		return "Najprv doplať dlžné mzdy."
	if s.money < int(C.WASH.cost):
		return "Čistenie potrebuje " + str(C.WASH.cost) + " ₵ na vodu a energiu."
	if available(s, w.product) < 1:
		return "Chýba voľný odliatok v sklade. Vyrob ho a presuň do skladu; rezervované kusy sa nepoužijú."
	if used(s, "goods") + reserved_output(s) > capacity(s, "goods"):
		return "Sklad je preplnený."
	return ""

static func start_wash(s: Dictionary) -> Dictionary:
	var err: String = can_wash(s)
	if not err.is_empty():
		return fail_res(err)
	var w: Dictionary = s.washer
	consume_goods(s, w.product, 1)
	s.money -= int(C.WASH.cost)
	w.active = w.product
	w.elapsed = 0.0
	log_msg(s, "Pieskovač: " + C.PRODUCTS[w.active].name + " naložená zo skladu · voda a energia −" + str(C.WASH.cost) + " ₵.", "production")
	return ok_res("Výrobok sa nakladá sprava. Čistenie trvá " + str(C.WASH.total) + " sekúnd.")

static func washer_action(s: Dictionary, c: Dictionary) -> Dictionary:
	var w: Dictionary = s.washer
	var act: String = c.get("action", "")
	if act == "start":
		return start_wash(s)
	if act == "configure":
		if w.active != null:
			return fail_res("Počkaj na dokončenie výrobku.")
		var prod: String = c.get("product", "")
		if not C.WASH.outputs.has(prod):
			return fail_res("Vyber rúru, oceľový prstenec alebo bronzové puzdro.")
		w.product = prod
		s.revision += 1
		return ok_res("Program čistenia nastavený.")
	if act == "auto":
		if not (c.get("enabled") is bool):
			return fail_res("Neplatné nastavenie série.")
		w.auto = c.enabled
		s.revision += 1
		return ok_res("Automatické čistenie zapnuté." if w.auto else "Automatické čistenie vypnuté; rozpracovaný výrobok sa dokončí.")
	return fail_res("Neznáma akcia pieskovača.")

static func perform(s: Dictionary, command: Dictionary) -> Dictionary:
	var result: Dictionary = fail_res("Neznámy príkaz.")
	var t: String = command.get("type", "")
	if t == "cnc":
		result = cnc_action(s, command)
	elif t == "personnel" or t == "employment":
		result = personnel_action(s, command)
	elif t == "washer":
		result = washer_action(s, command)
	elif t == "store":
		result = store_material(s, command.get("material", ""), int(command.get("quantity", 0)))
	elif t == "expandBin":
		result = expand_bin(s, command.get("material", ""))
	elif t == "payWages":
		result = pay_debt(s)
	elif t == "machine":
		result = act_machine(s, int(command.get("slot", 0)), command.get("action", ""), command)
	elif t == "trade":
		result = trade(s, command.get("item", ""), command.get("side", ""), int(command.get("quantity", 0)))
	elif t == "limit":
		result = limit_sell(s, command.get("product", ""), int(command.get("quantity", 0)), int(command.get("minPrice", 0)))
	elif t == "cancelLimit":
		var oid: int = int(command.get("id", 0))
		var initial_len: int = s.limits.size()
		s.limits = s.limits.filter(func(o): return o.id != oid)
		if s.limits.size() == initial_len:
			return fail_res("Pokyn neexistuje.")
		log_msg(s, "Predajný pokyn zrušený. Výrobky sú opäť voľné.", "order")
		result = ok_res("Rezervácia zrušená.")
	elif t == "contract":
		result = contract_action(s, command.get("id", ""), command.get("action", ""))
	elif t == "expand":
		result = expand(s, command.get("kind", ""))
	elif t == "unlock":
		result = unlock_recipe(s, command.get("product", ""))
	elif t == "logistics":
		if s.logistics >= 2:
			return fail_res("Záves má najvyššiu úroveň.")
		var cost: int = 420 * (s.logistics + 1)
		if s.money < cost + 50:
			return fail_res("Potrebuješ " + str(cost + 50) + " ₵ vrátane rezervy.")
		s.money -= cost
		s.logistics += 1
		log_msg(s, "Rýchlejší pojazdný záves · −" + str(cost) + " ₵", "upgrade")
		result = ok_res("Obsluha panvy je rýchlejšia o " + str(s.logistics * 25) + " %.")

	if result.ok:
		milestones(s)
		s.revision += 1
	return result

static func automation(s: Dictionary) -> void:
	for i in range(C.SLOTS):
		var m: Variant = s.machines[i]
		if m != null:
			if m.state == "ready" and operator(s, i) != null:
				collect(s, i)
			if m.auto and m.state == "idle" and can_cast(s, i).is_empty():
				begin_cast(s, i)
	if s.washer.auto and can_wash(s).is_empty():
		start_wash(s)

static func tick(s: Dictionary, dt: float) -> Array:
	if dt <= 0.0:
		return []
	var ready_machines: Array = []
	var remaining: float = dt

	while remaining > C.EPS:
		sync_personnel(s)
		automation(s)

		if s.delivery == null and (not s.get("hr") or (duty(s, "ladle") != null and duty(s, "furnace") != null)) and s.queue.size() > 0 and s.machines[s.queue[0]].elapsed >= C.FLOW.spinup - C.EPS:
			var slot: int = s.queue.pop_front()
			s.machines[slot].served = true
			var d_ladle: Variant = duty(s, "ladle")
			var d_furn: Variant = duty(s, "furnace")
			s.delivery = {
				"slot": slot,
				"returnElapsed": null,
				"crew": shift(s),
				"employeeId": d_ladle.id if d_ladle != null else null,
				"furnaceId": d_furn.id if d_furn != null else null
			}

		var next_q: float = float(int(floor((s.clock + C.EPS) / C.QUOTE_INTERVAL)) + 1) * C.QUOTE_INTERVAL - s.clock
		var step: float = minf(remaining, next_q)
		step = minf(step, next_pay(s) - s.clock)
		step = minf(step, next_shift(s) - s.clock)
		step = minf(step, next_foreman_change(s) - s.clock)

		if washer_running(s):
			step = minf(step, float(C.WASH.total) - float(s.washer.elapsed))

		for m in s.machines:
			if m != null:
				if m.state == "unloading":
					step = minf(step, C.UNLOAD_SECONDS - float(m.unloadElapsed))
				if m.state == "failed":
					step = minf(step, C.FAILURE_SECONDS - float(m.failedElapsed))
				if m.state == "working":
					if not m.served and float(m.elapsed) < C.FLOW.spinup - C.EPS:
						step = minf(step, C.FLOW.spinup - float(m.elapsed))
					if m.served:
						var rate: float = logistics(s) if float(m.elapsed) < C.FLOW.pourEnd - C.EPS else 1.0
						step = minf(step, (duration(m.level, m.product) - float(m.elapsed)) / rate)

		for c in s.contracts:
			var end_t: Variant = c.deadline if c.status == "active" else (c.offerDeadline if c.status == "offer" else null)
			if end_t != null and float(end_t) > s.clock + C.EPS:
				step = minf(step, float(end_t) - s.clock)

		if s.delivery != null:
			var d: Dictionary = s.delivery
			if d.returnElapsed == null:
				var m_slot: Dictionary = s.machines[d.slot]
				step = minf(step, (C.FLOW.pourEnd - float(m_slot.elapsed)) / logistics(s))
			else:
				step = minf(step, (C.FLOW.returnTime - float(d.returnElapsed)) / logistics(s))

		if step <= C.EPS:
			break

		var before_week: int = week(s)
		var before_day: int = day(s)
		var before_shift: int = shift(s)
		var before_foreman: int = foreman_shift(s)
		var before_quote: int = int(floor((s.clock + C.EPS) / C.QUOTE_INTERVAL))
		var returning: bool = s.delivery != null and s.delivery.returnElapsed != null

		for i in range(C.SLOTS):
			var m: Variant = s.machines[i]
			if m == null:
				continue
			if m.state == "unloading":
				m.unloadElapsed = minf(C.UNLOAD_SECONDS, m.unloadElapsed + step)
				if m.unloadElapsed >= C.UNLOAD_SECONDS - C.EPS:
					s.goods[m.product] += 1
					s.pallets[i][m.product] += 1
					log_msg(s, "+1 " + C.PRODUCTS[m.product].name + " na železnú paletu · stroj " + str(i + 1), "stock")
					m.state = "idle"
					m.elapsed = 0.0
					m.served = false
					m.unloadElapsed = 0.0
				continue
			if m.state == "failed":
				m.failedElapsed = minf(C.FAILURE_SECONDS, m.failedElapsed + step)
				if m.failedElapsed >= C.FAILURE_SECONDS - C.EPS:
					m.state = "idle"
					m.elapsed = 0.0
					m.served = false
					m.reject = false
					log_msg(s, "Stroj " + str(i + 1) + ": nepodarok odstránený. Pripravený na novú dávku.", "warning")
				continue
			if m.state != "working":
				continue
			if m.served:
				var spd: float = logistics(s) if float(m.elapsed) < C.FLOW.pourEnd - C.EPS else 1.0
				m.elapsed = minf(duration(m.level, m.product), m.elapsed + step * spd)
			else:
				m.elapsed = minf(C.FLOW.spinup, m.elapsed + step)

			if m.served and m.reject and float(m.elapsed) >= C.FLOW.pourEnd - C.EPS:
				m.elapsed = C.FLOW.pourEnd
				m.state = "failed"
				m.failedElapsed = 0.0
				s.scrapped += 1
				log_msg(s, "NEPODAROK · stroj " + str(i + 1) + ": " + C.PRODUCTS[m.product].name + ". Vsádzka spotrebovaná, žiadny predajný výrobok.", "warning")
				continue

			if m.served and float(m.elapsed) >= duration(m.level, m.product) - C.EPS:
				m.elapsed = duration(m.level, m.product)
				m.state = "ready"
				m.finishedAt = s.clock + step
				s.made += 1
				ready_machines.append(i)
				log_msg(s, "Hotovo na stroji " + str(i + 1) + ": " + C.PRODUCTS[m.product].name, "production")

		if s.delivery != null:
			var d: Dictionary = s.delivery
			if returning:
				d.returnElapsed += step * logistics(s)
				if float(d.returnElapsed) >= C.FLOW.returnTime - C.EPS:
					s.delivery = null
			elif float(s.machines[d.slot].elapsed) >= C.FLOW.pourEnd - C.EPS:
				s.machines[d.slot].elapsed = maxf(float(s.machines[d.slot].elapsed), C.FLOW.pourEnd)
				d.returnElapsed = 0.0

		if s.get("hr"):
			accrue_personnel(s, step)

		if washer_running(s):
			var w: Dictionary = s.washer
			w.elapsed = minf(float(C.WASH.total), float(w.elapsed) + step)
			if float(w.elapsed) >= float(C.WASH.total) - C.EPS:
				var out_id: String = C.WASH.outputs[w.active]
				s.goods[out_id] += 1
				w.cleaned += 1
				w.lastProduct = w.active
				w.lastAt = s.clock + step
				w.active = null
				w.elapsed = 0.0
				log_msg(s, "Pieskovač: +1 " + C.PRODUCTS[out_id].name + " do skladu.", "stock")

		s.clock += step
		remaining -= step
		expire_contracts(s)

		if day(s) != before_day:
			offers(s)
			log_msg(s, "Deň " + str(day(s)) + ": " + event(s).title + ". Nové ponuky zákaziek.", "market")
		if week(s) != before_week:
			pay_personnel(s, before_shift)
		if shift(s) != before_shift:
			s.previousShift = before_shift
			s.lastShift = shift(s)
			s.shiftChangedAt = s.clock
			s.shiftChanges += 1
			sync_personnel(s)
			var active_names: Array = []
			for e in working_employees(s):
				if e.role != "foreman":
					active_names.append(e.name)
			var roster: String = ("v práci: " + ", ".join(active_names)) if active_names.size() > 0 else "žiadni pracovníci vo výrobe ani sklade"
			log_msg(s, "Smena " + C.CREWS[shift(s)].hours + " · " + roster + ".", "crew")
		if foreman_shift(s) != before_foreman:
			sync_personnel(s)
			var d_fm: Variant = duty(s, "foreman")
			var fm_name: String = d_fm.name if d_fm != null else "Chýba majster"
			log_msg(s, fm_name + " · dohľad " + C.FOREMEN[foreman_shift(s)].hours + ".", "crew")
		if int(floor((s.clock + C.EPS) / C.QUOTE_INTERVAL)) != before_quote:
			check_orders(s)
			s.revision += 1

	sync_personnel(s)
	automation(s)
	milestones(s)
	return ready_machines

static func is_integer(v: Variant, min_v: int = 0, max_v: int = 1000000000) -> bool:
	if not (v is int or v is float):
		return false
	var n: float = float(v)
	if n != floor(n) or n < float(min_v) or n > float(max_v):
		return false
	return true

static func restore_personnel(s: Dictionary, a: Dictionary) -> void:
	if int(a.get("version", 0)) < 12 or not a.get("hr"):
		init_personnel(s)
		return
	var h: Dictionary = a.hr
	var valid_positions: Dictionary = {}
	for p in positions(s):
		valid_positions[p.key] = true
	var h_rng: int = int(h.rng) if is_integer(h.get("rng"), 0, 4294967295) else 12345
	var h_next_id: int = int(h.nextId) if is_integer(h.get("nextId"), 1) else 1
	var h_started_at: float = float(h.startedAt) if (h.has("startedAt") and (h.startedAt is int or h.startedAt is float)) else s.clock
	s.hr = {
		"rng": h_rng,
		"nextId": h_next_id,
		"employees": [],
		"candidates": {},
		"attendance": {},
		"covers": [],
		"lines": {},
		"startedAt": h_started_at
	}
	var ids: Dictionary = {}
	var filled: Dictionary = {}
	var emp_list: Array = h.get("employees", []) if (h.get("employees") is Array) else []
	for e in emp_list:
		if not (e is Dictionary) or not (e.get("id") is String) or ids.has(e.id):
			continue
		if not C.JOBS.has(e.get("role")):
			continue
		var max_cr: int = 1 if e.role == "foreman" else 2
		if not is_integer(e.get("crew"), 0, max_cr) or not is_integer(e.get("slot"), -1, 5):
			continue
		if not (e.get("salary") is int or e.get("salary") is float) or float(e.salary) < 1.0 or float(e.salary) > 200.0:
			continue
		if has_defect(e.role) and not is_integer(e.get("defect"), 1, 15):
			continue
		if not (e.get("absence") is int or e.get("absence") is float) or float(e.absence) < 0.5 or float(e.absence) > 10.0:
			continue
		if not (e.get("hiredAt") is int or e.get("hiredAt") is float):
			continue
		var key: String = position_key(e.role, int(e.crew), int(e.slot))
		if not valid_positions.has(key) or (bool(e.get("active")) and filled.has(key)):
			continue
		ids[e.id] = true
		if bool(e.get("active")):
			filled[key] = true
		var emp_data: Dictionary = role_traits(e.role, e)
		emp_data["id"] = str(e.id).substr(0, 50)
		emp_data["name"] = str(e.name).substr(0, 60)
		emp_data["position"] = key
		emp_data["crew"] = int(e.crew)
		emp_data["slot"] = int(e.slot)
		if emp_data.has("defect"):
			emp_data["defect"] = int(e.defect)
		emp_data["active"] = e.get("active") == true
		emp_data["hiredAt"] = clampf(float(e.hiredAt), 0.0, s.clock)
		emp_data["appearance"] = 1 if e.get("appearance") == 1 else 0
		s.hr.employees.append(emp_data)

	for p in positions(s):
		var list_cand = h.get("candidates", {}).get(p.key)
		if list_cand is Array and list_cand.size() >= 2 and list_cand.size() <= 5:
			var all_ok: bool = true
			for c in list_cand:
				if not (c is Dictionary) or not (c.get("id") is String):
					all_ok = false
					break
				if not (c.get("salary") is int or c.get("salary") is float) or float(c.salary) < 1.0 or float(c.salary) > 200.0:
					all_ok = false
					break
				if has_defect(p.role) and not is_integer(c.get("defect"), 1, 15):
					all_ok = false
					break
				if not (c.get("absence") is int or c.get("absence") is float) or float(c.absence) < 0.5 or float(c.absence) > 10.0:
					all_ok = false
					break
			if all_ok:
				var c_mapped: Array = []
				for c in list_cand:
					var cd_data: Dictionary = role_traits(p.role, c)
					cd_data["salary"] = candidate_salary(p.role, c.get("defect"), float(c.absence))
					cd_data["name"] = str(c.name).substr(0, 60)
					if cd_data.has("defect"):
						cd_data["defect"] = int(c.defect)
					c_mapped.append(cd_data)
				s.hr.candidates[p.key] = c_mapped

		var att = h.get("attendance", {}).get(p.key)
		if att is Dictionary and (att.get("cycle") is int or att.get("cycle") is float) and (att.get("employeeId") is String):
			s.hr.attendance[p.key] = {
				"cycle": int(att.cycle),
				"employeeId": att.employeeId,
				"absent": att.get("absent") == true
			}

	var covers_list: Array = h.get("covers", []) if (h.get("covers") is Array) else []
	for c in covers_list:
		if not (c is Dictionary):
			continue
		var pos_match: Variant = null
		for p in positions(s):
			if p.key == c.get("position"):
				pos_match = p
				break
		var emp_c: Variant = employee(s, str(c.get("employeeId", "")))
		if pos_match != null and emp_c != null and emp_c.active and emp_c.role == pos_match.role and (c.get("until") is int or c.get("until") is float):
			var u_val: float = float(c.until)
			if u_val > s.clock and u_val <= position_end(s, pos_match) + C.EPS:
				var already: bool = false
				for o in s.hr.covers:
					if o.position == c.position or o.employeeId == c.employeeId:
						already = true
						break
				if not already:
					s.hr.covers.append(c.duplicate(true))

	for id_k in h.get("lines", {}).keys():
		var l = h.lines[id_k]
		if l is Dictionary:
			var ok_nums: bool = true
			for k in ["normal", "overtime", "severance"]:
				if not (l.get(k) is int or l.get(k) is float) or float(l[k]) < 0.0 or float(l[k]) > 1e7:
					ok_nums = false
					break
			if ok_nums:
				var line_dict: Dictionary = {
					"employeeId": id_k,
					"name": str(l.get("name", "")).substr(0, 80),
					"normal": float(l.normal),
					"overtime": float(l.overtime),
					"severance": float(l.severance)
				}
				if l.get("role") == "operator" and is_integer(l.get("slot"), 0, C.SLOTS - 1) and [0, 1, 2].has(int(l.get("crew"))):
					line_dict["role"] = l.role
					line_dict["slot"] = int(l.slot)
					line_dict["crew"] = int(l.crew)
				s.hr.lines[id_k] = line_dict

	s.operators = []
	for slot in range(C.SLOTS):
		var crew_arr = [0, 1, 2].map(func(c): return assigned(s, position_key("operator", c, slot)) != null)
		s.operators.append(crew_arr)
	sync_personnel(s)

static func restore(raw: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return fresh()
	var a: Dictionary = parsed
	var v: int = int(a.get("version", 0))
	if v < 1 or v > 14 or not is_integer(a.get("money")) or not is_integer(a.get("sold")):
		return fresh()
	if not (a.get("machines") is Array) or a.machines.size() != C.SLOTS or a.machines[0] == null:
		return fresh()

	if v < 7:
		for k in ["raw", "incoming", "bins"]:
			if a.has(k) and a[k] is Dictionary and a[k].has("coke"):
				a[k]["zinc"] = a[k]["coke"]
				a[k].erase("coke")
		if a.get("contracts") is Array:
			for c in a.contracts:
				if c is Dictionary and ["offer", "active"].has(c.get("status")) and is_integer(c.get("payout"), 1):
					c.payout = int(max(1, round(float(c.payout) * 0.75)))

	if v < 13 and a.get("hr") is Dictionary:
		for e in a.hr.get("employees", []):
			if e is Dictionary and (e.get("absence") is int or e.get("absence") is float):
				e.absence = float(e.absence) / 2.0
		for list_c in a.hr.get("candidates", {}).values():
			if list_c is Array:
				for c in list_c:
					if c is Dictionary and (c.get("absence") is int or c.get("absence") is float):
						c.absence = float(c.absence) / 2.0

	var s: Dictionary = fresh()
	s.cncOwned = []
	for i in range(7):
		s.cncOwned.append(i < 6 and v >= 14 and a.get("cncOwned") is Array and i < a.cncOwned.size() and a.cncOwned[i] == true)
	s.cncPower = []
	for i in range(7):
		s.cncPower.append(bool(s.cncOwned[i]) and a.get("cncPower") is Array and i < a.cncPower.size() and a.cncPower[i] == true)

	s.binUnlocked = {}
	for id in C.MATERIALS.keys():
		var unl: bool = v < 13 or id == "iron" or id == "zinc" or (a.get("binUnlocked") is Dictionary and a.binUnlocked.get(id) == true)
		s.binUnlocked[id] = unl

	s.rng = int(a.rng) if is_integer(a.get("rng"), 0, 4294967295) else s.rng
	s.scrapped = int(a.scrapped) if is_integer(a.get("scrapped")) else 0
	s.money = int(a.money)
	s.sold = int(a.sold)
	s.selected = int(a.selected) if is_integer(a.get("selected"), 0, 5) else 0

	s.machines = []
	for m_val in a.machines:
		if m_val == null:
			s.machines.append(null)
			continue
		if not (m_val is Dictionary) or not [1, 2, 3].has(int(m_val.get("level", 0))) or not ["idle", "working", "ready", "failed", "unloading"].has(m_val.get("state", "")):
			return fresh()
		var p_name: String = m_val.get("product", "iron_pipe")
		if not C.PRODUCTS.has(p_name) or C.PRODUCTS[p_name].finished:
			p_name = "iron_pipe"
		var m_dict: Dictionary = {
			"level": int(m_val.level),
			"state": m_val.state,
			"employeeId": str(m_val.employeeId) if (m_val.get("employeeId") is String) else null,
			"unloadEmployeeId": str(m_val.unloadEmployeeId) if (m_val.get("unloadEmployeeId") is String) else null,
			"batchRisk": clampf(float(m_val.batchRisk), 0.0, 1.0) if (m_val.get("batchRisk") is int or m_val.get("batchRisk") is float) else null,
			"unloadElapsed": clampf(float(m_val.get("unloadElapsed", 0.0)), 0.0, C.UNLOAD_SECONDS - C.EPS * 2.0),
			"unloadCrew": int(m_val.unloadCrew) if is_integer(m_val.get("unloadCrew"), 0, 2) else 0,
			"product": p_name,
			"auto": m_val.get("auto") == true,
			"reject": v >= 7 and m_val.get("reject") == true and failure_risk({ "level": m_val.level, "product": p_name }) > 0.0,
			"failedElapsed": clampf(float(m_val.get("failedElapsed", 0.0)), 0.0, C.FAILURE_SECONDS - C.EPS * 2.0),
			"finishedAt": float(m_val.finishedAt) if (m_val.get("finishedAt") is int or m_val.get("finishedAt") is float) else null,
			"served": m_val.state != "idle" if v == 1 else m_val.get("served") == true,
			"elapsed": minf(duration(int(m_val.level), p_name), float(m_val.get("elapsed", 0.0)))
		}
		s.machines.append(m_dict)

	if v >= 3:
		for k in ["made", "revenue", "reputation", "completedContracts", "shiftChanges"]:
			s[k] = int(a[k]) if is_integer(a.get(k)) else 0
		s.clock = float(a.clock) if (a.get("clock") is int or a.get("clock") is float) and float(a.clock) >= 0.0 and float(a.clock) < 1e9 else 45.0
		s.lastShift = shift(s)
		s.previousShift = int(a.previousShift) if is_integer(a.get("previousShift"), 0, 2) else (s.lastShift + 2) % 3
		s.shiftChangedAt = clampf(float(a.shiftChangedAt), 0.0, s.clock) if (a.get("shiftChangedAt") is int or a.get("shiftChangedAt") is float) else s.clock
		s.storage = {
			"raw": int(a.get("storage", {}).get("raw", 0)) if is_integer(a.get("storage", {}).get("raw"), 0, 5) else 0,
			"goods": int(a.get("storage", {}).get("goods", 0)) if is_integer(a.get("storage", {}).get("goods"), 0, 5) else 0
		}
		for kind in ["raw", "goods"]:
			for id in s[kind].keys():
				s[kind][id] = int(a.get(kind, {}).get(id, 0)) if is_integer(a.get(kind, {}).get(id), 0, 100000) else 0
		var unl_list: Array = ["iron_pipe", "ring"]
		if a.get("unlocked") is Array:
			for uid in a.unlocked:
				if C.PRODUCTS.has(uid) and not C.PRODUCTS[uid].finished and not unl_list.has(uid):
					unl_list.append(uid)
		s.unlocked = unl_list
		s.logistics = int(a.logistics) if is_integer(a.get("logistics"), 0, 2) else 0
		s.milestones = []
		if a.get("milestones") is Array:
			for mid in a.milestones:
				for g in C.GOALS:
					if g.id == mid and not s.milestones.has(mid):
						s.milestones.append(mid)

		s.contracts = []
		if a.get("contracts") is Array:
			for c in a.contracts:
				if c is Dictionary and (c.get("id") is String) and C.PRODUCTS.has(c.get("product")) and is_integer(c.get("quantity"), 1, 100) and is_integer(c.get("payout"), 1, 10000000) and ["offer", "active", "done", "expired", "lapsed"].has(c.get("status")):
					var off_dl: float = float(c.offerDeadline) if (v >= 9 and (c.get("offerDeadline") is int or c.get("offerDeadline") is float)) else s.clock + C.OFFER_SECONDS
					var acc_at: Variant = float(c.acceptedAt) if (c.get("acceptedAt") is int or c.get("acceptedAt") is float) else (float(c.deadline) - C.DELIVERY_SECONDS if c.status == "active" else null)
					s.contracts.append({
						"id": c.id,
						"product": c.product,
						"quantity": int(c.quantity),
						"payout": int(c.payout),
						"buyer": str(c.get("buyer", "")).substr(0, 60),
						"status": c.status,
						"deadline": float(c.deadline) if c.status == "active" else null,
						"offerDeadline": off_dl,
						"acceptedAt": acc_at,
						"bonus": int(c.bonus) if is_integer(c.get("bonus"), -30, 30) else 0
					})
					if s.contracts.size() >= 12:
						break

		s.limits = []
		if a.get("limits") is Array:
			for o in a.limits:
				if s.limits.size() < 5 and o is Dictionary and is_integer(o.get("id"), 1) and saleable(str(o.get("product"))) and is_integer(o.get("quantity"), 1, 1000) and is_integer(o.get("minPrice"), 1, 100000) and available(s, o.product) >= int(o.quantity):
					s.limits.append({
						"id": int(o.id),
						"product": o.product,
						"quantity": int(o.quantity),
						"minPrice": int(o.minPrice),
						"created": float(o.created) if (o.get("created") is int or o.get("created") is float) else s.clock
					})
		var max_limit_id: int = 1
		for o in s.limits:
			if o.id >= max_limit_id:
				max_limit_id = o.id + 1
		s.nextId = max(int(a.get("nextId", 1)), max_limit_id)
		s.ledger = []
		if a.get("ledger") is Array:
			for l in a.ledger:
				if l is Dictionary and (l.get("clock") is int or l.get("clock") is float) and (l.get("text") is String):
					var txt: String = l.text.substr(0, 250).replace("Koks", "Zinok").replace("koksu", "zinku").replace("koks", "zinok")
					s.ledger.append({
						"clock": float(l.clock),
						"text": txt,
						"type": str(l.get("type", "info")).substr(0, 20)
					})
					if s.ledger.size() >= 40:
						break
	else:
		s.raw = { "iron": 36, "steel": 15, "copper": 8, "tin": 3, "zinc": 16 }
		s.made = s.sold
		if s.sold >= 12:
			s.milestones = ["sales"]
		log_msg(s, "Rozšírenie dielne: stroje a peniaze zachované, štartovacie suroviny doplnené.", "stock")

	s.incoming = empty_raw()
	s.bins = empty_raw()
	s.payroll = new_payroll()
	for id in C.MATERIALS.keys():
		if v >= 4:
			s.incoming[id] = int(a.get("incoming", {}).get(id, 0)) if is_integer(a.get("incoming", {}).get(id), 0, 100000) else 0
			s.bins[id] = int(a.get("bins", {}).get(id, 0)) if is_integer(a.get("bins", {}).get(id), 0, 20000) else 0
		else:
			s.bins[id] = s.storage.raw
		s.bins[id] = int(max(s.bins[id], ceil(float(s.raw[id]) / float(C.BIN_BASE[id])) - 1))

	if v >= 4 and a.get("payroll") is Dictionary:
		var p_in = a.payroll
		s.payroll.accrued = clampf(float(p_in.get("accrued", 0.0)), 0.0, 1e8)
		for k in ["paid", "debt"]:
			s.payroll[k] = int(p_in.get(k, 0)) if is_integer(p_in.get(k)) else 0
		s.payroll.operatorAccrued = []
		for i in range(C.SLOTS):
			var op_acc = p_in.get("operatorAccrued", [])
			s.payroll.operatorAccrued.append(clampf(float(op_acc[i]), 0.0, 1e7) if (op_acc is Array and i < op_acc.size() and (op_acc[i] is int or op_acc[i] is float)) else 0.0)
		s.payroll.operatorByCrew = []
		for i in range(C.SLOTS):
			var crew_row = []
			for crw in range(3):
				var val_crw: float = 0.0
				if v >= 11 and p_in.get("operatorByCrew") is Array and i < p_in.operatorByCrew.size() and p_in.operatorByCrew[i] is Array and crw < p_in.operatorByCrew[i].size():
					val_crw = clampf(float(p_in.operatorByCrew[i][crw]), 0.0, 1e7)
				elif v < 11 and crw == shift(s):
					val_crw = s.payroll.operatorAccrued[i]
				crew_row.append(val_crw)
			s.payroll.operatorByCrew.append(crew_row)

		var f_acc = p_in.get("foremenAccrued", [0.0, 0.0])
		if f_acc is Array and f_acc.size() == 2:
			s.payroll.foremenAccrued = [float(f_acc[0]), float(f_acc[1])]

		s.payroll.history = []
		if p_in.get("history") is Array:
			for h in p_in.history:
				if h is Dictionary and is_integer(h.get("due")) and is_integer(h.get("paid")) and int(h.paid) <= int(h.due):
					var h_entry = {
						"clock": float(h.get("clock", 0.0)),
						"crew": int(h.get("crew", 0)),
						"due": int(h.due),
						"paid": int(h.paid),
						"team": h.get("team") == true
					}
					if h.get("weekly") == true:
						h_entry["weekly"] = true
					if h.get("employees") is Array:
						var emp_arr = []
						for eh in h.employees:
							if eh is Dictionary:
								var eh_copy: Dictionary = eh.duplicate(true)
								eh_copy["name"] = str(eh.get("name", "")).substr(0, 80)
								eh_copy["normal"] = float(eh.get("normal", 0.0))
								eh_copy["overtime"] = float(eh.get("overtime", 0.0))
								eh_copy["severance"] = float(eh.get("severance", 0.0))
								emp_arr.append(eh_copy)
						h_entry["employees"] = emp_arr
						h_entry["severance"] = int(h.get("severance", 0))

					var ops_arr: Array = []
					if h.get("operators") is Array:
						for o in h.operators:
							if o is Dictionary and is_integer(o.get("slot"), 0, 5) and (o.get("amount") is int or o.get("amount") is float) and float(o.amount) >= 0.0:
								var o_entry: Dictionary = {
									"slot": int(o.slot),
									"amount": float(o.amount)
								}
								if is_integer(o.get("crew"), 0, 2):
									o_entry["crew"] = int(o.crew)
								var op_crw: int = int(o.crew) if is_integer(o.get("crew"), 0, 2) else int(h.get("crew", 0))
								o_entry["name"] = str(o.name).substr(0, 60) if (v >= 12 and o.has("name")) else C.OPERATORS[int(o.slot)][op_crw]
								ops_arr.append(o_entry)
					h_entry["operators"] = ops_arr

					if h.get("foremen") is Array:
						h_entry["foremen"] = [float(h.foremen[0]), float(h.foremen[1])]

					s.payroll.history.append(h_entry)
					if s.payroll.history.size() >= 12:
						break

	if v >= 8 and a.get("washer") is Dictionary:
		var w_in = a.washer
		var w_prod = w_in.get("product", "iron_pipe")
		s.washer.product = w_prod if C.WASH.outputs.has(w_prod) else "iron_pipe"
		s.washer.auto = w_in.get("auto") == true
		s.washer.cleaned = int(w_in.get("cleaned", 0)) if is_integer(w_in.get("cleaned")) else 0
		var w_act = w_in.get("active")
		if w_act is String and C.WASH.outputs.has(w_act) and (w_in.get("elapsed") is int or w_in.get("elapsed") is float):
			var el = float(w_in.elapsed)
			if el >= 0.0 and el < C.WASH.total:
				s.washer.active = w_act
				s.washer.product = w_act
				s.washer.elapsed = el
		var w_lp = w_in.get("lastProduct")
		s.washer.lastProduct = w_lp if (w_lp is String and C.WASH.outputs.has(w_lp)) else null
		s.washer.lastAt = clampf(float(w_in.lastAt), 0.0, s.clock) if (w_in.get("lastAt") is int or w_in.get("lastAt") is float) else null

	if v >= 9:
		for buyer in C.COMPANIES:
			var r_in = a.get("relationships", {}).get(buyer)
			if r_in is Dictionary:
				s.relationships[buyer] = {
					"score": int(r_in.score) if is_integer(r_in.get("score"), -100, 100) else 0,
					"delivered": int(r_in.delivered) if is_integer(r_in.get("delivered")) else 0,
					"missed": int(r_in.missed) if is_integer(r_in.get("missed")) else 0
				}

	if v >= 10:
		s.operators = []
		for slot in range(C.SLOTS):
			var op_c = []
			for crw in range(3):
				op_c.append(s.machines[slot] != null and a.get("operators") is Array and slot < a.operators.size() and a.operators[slot] is Array and crw < a.operators[slot].size() and a.operators[slot][crw] == true)
			s.operators.append(op_c)
		var rem_pallets = s.goods.duplicate(true)
		for slot in range(C.SLOTS):
			for pid in C.PRODUCTS.keys():
				var n_pal = int(a.get("pallets", [])[slot].get(pid, 0)) if (a.get("pallets") is Array and slot < a.pallets.size() and a.pallets[slot] is Dictionary and is_integer(a.pallets[slot].get(pid), 0, 100000)) else 0
				var take_n = int(min(n_pal, rem_pallets[pid]))
				s.pallets[slot][pid] = take_n
				rem_pallets[pid] -= take_n
	else:
		for c in s.contracts:
			if ["offer", "active"].has(c.status) and C.WASH.outputs.has(c.product):
				c.product = C.WASH.outputs[c.product]
				if c.status == "active":
					c.deadline = maxf(float(c.deadline), s.clock + C.DELIVERY_SECONDS)
		log_msg(s, "Nové pravidlá: prijmi obsluhu ku každej odstredivke a smene. Rúry pred predajom vyčisti. Staré zákazky na rúry teraz žiadajú očistené kusy; aktívne dostali aspoň 135 s.", "crew")

	expire_contracts(s)
	s.stockMove = null
	s.delivery = null
	var d_in = a.get("delivery")
	if d_in is Dictionary and is_integer(d_in.get("slot"), 0, 5) and s.machines[int(d_in.slot)] != null:
		var slot_d: int = int(d_in.slot)
		var m_d: Dictionary = s.machines[slot_d]
		var ret_el: Variant = float(d_in.returnElapsed) if (d_in.get("returnElapsed") is int or d_in.get("returnElapsed") is float) else null
		if ret_el != null or (m_d.state == "working" and m_d.served and float(m_d.elapsed) >= C.FLOW.spinup and float(m_d.elapsed) < C.FLOW.pourEnd):
			s.delivery = {
				"slot": slot_d,
				"returnElapsed": ret_el,
				"crew": int(d_in.crew) if is_integer(d_in.get("crew"), 0, 2) else shift(s),
				"employeeId": str(d_in.employeeId) if (d_in.get("employeeId") is String) else null,
				"furnaceId": str(d_in.furnaceId) if (d_in.get("furnaceId") is String) else null
			}

	for i in range(C.SLOTS):
		var m_chk: Variant = s.machines[i]
		if m_chk != null and m_chk.state == "working":
			if float(m_chk.elapsed) < C.FLOW.pourEnd and (s.delivery == null or s.delivery.slot != i) and m_chk.served:
				m_chk.served = false
				m_chk.elapsed = C.FLOW.spinup
			if not m_chk.served:
				m_chk.elapsed = minf(float(m_chk.elapsed), C.FLOW.spinup)

	var pending_queue: Array = []
	for i in range(C.SLOTS):
		var m_q: Variant = s.machines[i]
		if m_q != null and m_q.state == "working" and not m_q.served:
			pending_queue.append(i)
	s.queue = []
	if a.get("queue") is Array:
		for qi in a.queue:
			if pending_queue.has(qi) and not s.queue.has(qi):
				s.queue.append(qi)
	for qi in pending_queue:
		if not s.queue.has(qi):
			s.queue.append(qi)

	if v < 13:
		for c in s.contracts:
			if ["offer", "active"].has(c.status) and C.WASH.outputs.has(c.product):
				c.product = C.WASH.outputs[c.product]
				if c.status == "active":
					c.deadline = maxf(float(c.deadline), s.clock + C.DELIVERY_SECONDS)
		s.ledger = s.ledger.filter(func(l): return not l.text.contains("preberá smenu") and not l.text.contains("preberá dohľad"))
		log_msg(s, "Novinky: polovičné absencie, riziko stroja + obsluha, všetky odliatky treba očistiť. Existujúce sklady ostali odomknuté.", "upgrade")

	restore_personnel(s, a)
	if v < 12:
		if s.delivery != null:
			var d_ladle = duty(s, "ladle")
			var d_furn = duty(s, "furnace")
			s.delivery.employeeId = d_ladle.id if d_ladle != null else null
			s.delivery.furnaceId = d_furn.id if d_furn != null else null
		for i in range(C.SLOTS):
			if s.machines[i] != null:
				var d_op = duty(s, "operator", i)
				s.machines[i].employeeId = d_op.id if d_op != null else null
				s.machines[i].unloadEmployeeId = s.machines[i].employeeId
		log_msg(s, "Kancelária otvorená. Existujúci pracovníci a mzdy zachovaní. Evidencia dĺžky zamestnania začína dnešným dňom.", "crew")

	if s.contracts.size() == 0:
		offers(s)
	s.revision = 0
	return s

