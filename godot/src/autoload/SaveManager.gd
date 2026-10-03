extends Node

const SAVE_PATH: String = "user://savegame.json"
const STORAGE_KEY: String = "zerava-zlievaren-v1"

var autosave_dirty: bool = false
var autosave_timer: float = 0.0

func _process(delta: float) -> void:
	if autosave_dirty:
		autosave_timer += delta
		if autosave_timer >= 2.0:
			autosave_dirty = false
			autosave_timer = 0.0
			save_game()

func request_autosave() -> void:
	autosave_dirty = true

func has_saved_game() -> bool:
	if OS.has_feature("web"):
		return not load_from_web().is_empty()
	return FileAccess.file_exists(SAVE_PATH)

func _get_gm() -> Node:
	return get_node_or_null("/root/GameManager")

func save_game() -> bool:
	var gm = _get_gm()
	if gm == null or gm.get("state") == null:
		return false
	var s: Dictionary = gm.state
	if s.is_empty():
		return false
	var json_str: String = JSON.stringify(s)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
	
	if OS.has_feature("web"):
		save_to_web(json_str)
	return true

func load_game() -> bool:
	var raw: String = ""
	if OS.has_feature("web"):
		raw = load_from_web()
	
	if raw.is_empty() and FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			raw = file.get_as_text()
			file.close()

	if not raw.is_empty():
		var restored: Dictionary = FoundryEngine.restore(raw)
		if not restored.is_empty():
			var gm = _get_gm()
			if gm != null:
				gm.state = restored
			return true
	return false

func export_json() -> String:
	var gm = _get_gm()
	if gm != null and gm.get("state") != null:
		return JSON.stringify(gm.state)
	return "{}"

func import_json(raw_json: String) -> bool:
	var restored: Dictionary = FoundryEngine.restore(raw_json)
	if not restored.is_empty():
		var gm = _get_gm()
		if gm != null:
			gm.state = restored
			save_game()
			var eb = get_node_or_null("/root/EventBus")
			if eb != null:
				eb.room_change_requested.emit(gm.get("current_room"))
				eb.machine_selected.emit(gm.get("selected_machine"))
			return true
	return false

func save_to_web(json_data: String) -> void:
	if OS.has_feature("web"):
		var safe_json: String = json_data.c_escape()
		var js_code: String = "localStorage.setItem('%s', \"%s\")" % [STORAGE_KEY, safe_json]
		JavaScriptBridge.eval(js_code)

func load_from_web() -> String:
	if OS.has_feature("web"):
		var js_code: String = "localStorage.getItem('%s') || ''" % STORAGE_KEY
		var res: Variant = JavaScriptBridge.eval(js_code)
		if res is String and not res.is_empty():
			return res
	return ""
