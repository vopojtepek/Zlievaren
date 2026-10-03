extends SceneTree

const TestOfficeUI = preload("res://tests/TestOfficeUI.gd")
const TestContractsUI = preload("res://tests/TestContractsUI.gd")

var _ran: bool = false

func _process(_delta: float) -> bool:
	if _ran:
		return false
	_ran = true

	print("\n=======================================")
	print("  Žeravá zlievareň — Godot Test Runner")
	print("=======================================\n")

	var suites: Array = [
		TestWasher.new(),
		TestWeekly.new(),
		TestRejects.new(),
		TestOperators.new(),
		TestContracts.new(),
		TestContractsUI.new(),
		TestUpdate19.new(),
		TestUpdate20.new(),
		TestUpdate21.new(),
		TestPersonnel.new(),
		TestSimulation.new(),
		TestVisualRooms.new(),
		TestOfficeUI.new()
	]

	var passed: int = 0
	var failed: int = 0

	for s in suites:
		var s_name = s.get_script().resource_path.get_file()
		print("\n=== " + s_name + " ===")
		var ok: bool = false
		if s is TestOfficeUI or s is TestContractsUI:
			ok = s.run_all(self)
		else:
			ok = s.run_all()
		if ok:
			passed += 1
		else:
			failed += 1

	print("\n=======================================")
	print("Test Summary: " + str(passed) + " passed, " + str(failed) + " failed out of " + str(suites.size()) + " suites.")
	print("=======================================\n")

	quit(1 if failed > 0 else 0)
	return true
