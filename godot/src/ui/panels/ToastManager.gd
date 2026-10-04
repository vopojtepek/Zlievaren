class_name ToastManager
extends Control

@export var max_toasts: int = 5
@onready var container: VBoxContainer = $VBoxContainer

func _ready() -> void:
	get_viewport().size_changed.connect(_resize_toasts)
	_resize_toasts()
	EventBus.toast_requested.connect(_on_toast_requested)

func _resize_toasts() -> void:
	var half = minf(300, maxf(0, get_viewport_rect().size.x / 2 - 16))
	container.offset_left = -half
	container.offset_right = half

func _on_toast_requested(message: String, is_error: bool) -> void:
	if message.is_empty():
		return
	
	var toast = PanelContainer.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	
	if is_error:
		style.bg_color = Color("#f1d1b7")
		style.border_color = Color("#f0d3b9")
	else:
		style.bg_color = Color("#dbead2")
		style.border_color = Color("#f0f9e3")
	style.set_border_width_all(1)
	toast.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#583326") if is_error else Color("#183828"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(label)
	
	container.add_child(toast)
	
	if container.get_child_count() > max_toasts:
		var oldest = container.get_child(0)
		oldest.queue_free()
	
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(toast, "modulate:a", 0.0, 0.6)
	tween.tween_callback(toast.queue_free)
