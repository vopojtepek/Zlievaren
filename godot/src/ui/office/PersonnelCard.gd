extends PanelContainer
const Portrait = preload("res://src/ui/office/PersonnelPortrait.gd")
var action_button: Button
var portrait: Control

func label_into(parent: Node, value: String, font_size: int = 14, color: Color = Color("383a32")) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func configure(person: Dictionary, position: Dictionary, state: Dictionary, candidate: bool, status: String, paused: bool) -> void:
	custom_minimum_size.x = 280
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	var paper = StyleBoxFlat.new()
	paper.bg_color = Color("f0e5cb")
	paper.border_color = Color("b7a584")
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(3)
	paper.set_content_margin_all(16)
	add_theme_stylebox_override("panel", paper)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	label_into(body, "UCHÁDZAČ" if candidate else "PERSONÁLNA KARTA", 11, Color("766449"))
	var header = BoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	body.add_child(header)
	portrait = Portrait.new()
	portrait.configure(person.name, position.role)
	header.add_child(portrait)
	var title = VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	label_into(title, person.name, 21)
	label_into(title, position.label, 14, Color("6d5940"))
	var status_color = Color("6d5940")
	if status == "V práci": status_color = Color("286348")
	elif status == "Neprišiel na smenu": status_color = Color("9a3430")
	elif status == "Nadčas": status_color = Color("815814")
	label_into(title, "K dispozícii" if candidate else status, 13, status_color)
	var separator = HSeparator.new()
	separator.modulate = Color("9b8968")
	body.add_child(separator)
	label_into(body, "Smena · " + position.get("hours", ""))
	var preview = person.duplicate(true)
	if candidate:
		for key in position: preview[key] = position[key]
	label_into(body, Format.cash(FoundryEngine.regular_shift_pay(preview)) + " / smena", 19)
	var skills = "Absencia: %.1f %%" % float(person.absence)
	if FoundryEngine.has_defect(position.role):
		skills = "Kvalita: %d %% · " % int(person.defect) + skills
	label_into(body, skills)
	if not candidate:
		label_into(body, "Zamestnaný: %d dní (%d mes.)" % [int(floor((state.clock - person.hiredAt) / Constants.DAY)), FoundryEngine.tenure(state, person)], 12)
		label_into(body, "Odstupné: " + Format.cash(FoundryEngine.severance(state, person)), 12)
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)
	action_button = Button.new()
	action_button.text = "Prijať" if candidate else "Prepustiť"
	if not candidate:
		action_button.tooltip_text = "Odstupné: " + Format.cash(FoundryEngine.severance(state, person))
	action_button.custom_minimum_size.y = 36
	action_button.disabled = paused
	body.add_child(action_button)
