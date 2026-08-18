extends Button

func _pressed() -> void:
	ButtonSound.play_sound()
	get_tree().change_scene_to_file("res://scenes/levels/level_1/level_1.tscn")
