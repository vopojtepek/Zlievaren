extends SceneTree

func _init() -> void:
	print("Smoke testing FoundryEngine...")
	var s = FoundryEngine.fresh()
	print("Initial money: ", s.money)
	print("Initial clock: ", s.clock)
	print("Day: ", FoundryEngine.day(s))
	print("Shift: ", FoundryEngine.shift(s))
	
	# Test a 10s tick
	var ready_machines = FoundryEngine.tick(s, 10.0)
	print("Clock after 10s: ", s.clock)
	print("Ready machines: ", ready_machines)
	
	print("FoundryEngine OK!")
	quit(0)
