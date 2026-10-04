extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var suite = preload("res://tests/TestOfficeUI.gd").new()
	var passed: bool = suite.run_all(self)
	await process_frame
	await process_frame
	quit(0 if passed else 1)
