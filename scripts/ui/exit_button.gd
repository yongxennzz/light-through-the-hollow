extends Button


func _pressed() -> void:
	ButtonSound.play_sound()
	get_tree().quit()
