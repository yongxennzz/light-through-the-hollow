extends TextureButton

func _ready() -> void:
	print(">>> PowerButton 的 _ready 执行了 <<<")
	pressed.connect(_on_self_pressed)

func _on_self_pressed() -> void:
	print(">>> PowerButton 自己检测到被点击了 <<<")

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print(">>> PowerButton 收到鼠标事件: ", event.pressed, " at ", event.position)
