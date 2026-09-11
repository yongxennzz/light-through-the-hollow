extends TextureButton
class_name DialButton

@export var dial_id: String = "A" 

@onready var pointer: Sprite2D = get_parent().get_node("pointer")

var rotation_state: int = 0         # 0~3 -> 0/90/180/270 degrees
signal rotated(dial_id: String, rotation_state: int)

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	rotation_state = (rotation_state + 1) % 4
	pointer.rotation_degrees = rotation_state * 90.0
	rotated.emit(dial_id, rotation_state)

func reset() -> void:
	rotation_state = 0
	pointer.rotation_degrees = 0
