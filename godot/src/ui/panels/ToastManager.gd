class_name ToastManager
extends Control

@export var max_toasts: int = 5
@onready var container: VBoxContainer = $VBoxContainer

func _ready() -> void:
	EventBus.toast_requested.connect(_on_toast_requested)

func _on_toast_requested(message: String, is_error: bool) -> void:
	if message.is_empty():
		return
	
	var toast = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	
	if is_error:
		style.bg_color = Color(0.65, 0.15, 0.15, 0.92)
		style.border_color = Color(0.9, 0.3, 0.3, 1.0)
	else:
		style.bg_color = Color(0.12, 0.28, 0.22, 0.92)
		style.border_color = Color(0.3, 0.7, 0.45, 1.0)
	style.set_border_width_all(1)
	toast.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	toast.add_child(label)
	
	container.add_child(toast)
	
	if container.get_child_count() > max_toasts:
		var oldest = container.get_child(0)
		oldest.queue_free()
	
	var tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(toast, "modulate:a", 0.0, 0.6)
	tween.tween_callback(toast.queue_free)
