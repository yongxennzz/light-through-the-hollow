extends TextureButton

func _ready() -> void:
	pressed.connect(_on_self_pressed)

func _on_self_pressed() -> void:
	print(">>> PowerButton self pressed <<<")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print(">>> PowerButton: ", event.pressed, " at ", event.position)
