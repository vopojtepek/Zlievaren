extends Node
## UI preferences are deliberately independent of the saved simulation.
signal mode_changed(mobile: bool)
const SETTINGS_PATH = "user://display.cfg"
var mobile: bool = false
var manual: bool = false
var settings_path: String = SETTINGS_PATH
var pending: bool = false

func _ready() -> void:
	load_preference()
	get_viewport().size_changed.connect(_viewport_changed)
	get_tree().node_added.connect(func(_node): schedule_adapt())
	_viewport_changed()

func load_preference() -> void:
	var config = ConfigFile.new()
	manual = config.load(settings_path) == OK and config.has_section_key("display", "mobile")
	if manual:
		mobile = bool(config.get_value("display", "mobile"))

func set_mobile(value: bool, persist: bool = true) -> void:
	if persist:
		manual = true
		var config = ConfigFile.new()
		config.set_value("display", "mobile", value)
		if config.save(settings_path) != OK:
			push_warning("Nastavenie zobrazenia sa nepodarilo uložiť.")
	if mobile != value:
		mobile = value
		mode_changed.emit(mobile)
	schedule_adapt()

func _viewport_changed() -> void:
	if not manual:
		set_mobile(get_viewport().get_visible_rect().size.x < 850, false)
	schedule_adapt()

func schedule_adapt() -> void:
	if not pending:
		pending = true
		_adapt_tree.call_deferred()

func _adapt_tree() -> void:
	pending = false
	for node in get_tree().get_nodes_in_group("responsive_ui"):
		adapt(node)

func remember(node: Object, property: String, value: Variant) -> void:
	var key = "desktop_" + property
	if not node.has_meta(key):
		node.set_meta(key, node.get(property))
	node.set(property, value if mobile else node.get_meta(key))

func adapt(node: Node) -> void:
	if node is Control and not node.has_meta("responsive_minimum"):
		var original: Vector2 = node.get_meta("desktop_custom_minimum_size", node.custom_minimum_size)
		var minimum = Vector2(0, original.y)
		if node is BaseButton or node is SpinBox or node is LineEdit:
			minimum = Vector2(44, maxf(44, original.y))
			if node is Button:
				var text_width = node.get_theme_font("font").get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, node.get_theme_font_size("font_size")).x
				minimum.x = clampf(maxf(original.x, text_width + 24), 44, 140)
				if node.has_meta("mobile_button_width"):
					minimum.x = node.get_meta("mobile_button_width")
		elif node is TextureRect:
			minimum = original
		remember(node, "custom_minimum_size", minimum)
	if node is BoxContainer and not node is VBoxContainer and not node is HBoxContainer and not node.has_meta("keep_horizontal") and not node.has_meta("responsive_orientation"):
		remember(node, "vertical", true)
	if node is GridContainer and not node.has_meta("responsive_columns"):
		remember(node, "columns", 1)
	if node is Label or node is Button:
		remember(node, "autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	if node is Button:
		remember(node, "clip_text", false)
	if node is ScrollContainer:
		remember(node, "horizontal_scroll_mode", ScrollContainer.SCROLL_MODE_DISABLED)
		if node.name == "VacancyScroll":
			remember(node, "vertical_scroll_mode", ScrollContainer.SCROLL_MODE_AUTO)
			node.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if node.name == "ScrollContent":
			remember(node, "custom_minimum_size", Vector2(0, 600))
	for child in node.get_children():
		adapt(child)
