extends Button

func _pressed() -> void:
	ButtonSound.play_sound()
	get_tree().change_scene_to_file("res://scenes/levels/level_2/level_2.tscn")
