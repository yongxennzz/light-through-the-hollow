extends Control
class_name DigitSlot

@export var color_id: String = "red"
@export var current_value: int = 0
@export var label: Label
@export var up_button: Button
@export var down_button: Button

func _ready() -> void:
	up_button.pressed.connect(_on_up_pressed)
	down_button.pressed.connect(_on_down_pressed)
	_update_label()

func _on_up_pressed() -> void:
	current_value = wrapi(current_value + 1, 0, 10)
	_update_label()

func _on_down_pressed() -> void:
	current_value = wrapi(current_value - 1, 0, 10)
	_update_label()

func _update_label() -> void:
	label.text = str(current_value)
