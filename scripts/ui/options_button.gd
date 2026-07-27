extends Button

func _pressed() -> void:
	ButtonSound.play_sound()
	get_tree().change_scene_to_file("res://scenes/ui/options.tscn")
