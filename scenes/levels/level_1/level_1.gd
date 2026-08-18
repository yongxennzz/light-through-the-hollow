extends Node2D
@onready var win_label = $CanvasLayer/WinLabel
@onready var congratulations_sound = $CongratulationsSound

func level_complete():
	win_label.visible = true
	win_label.scale = Vector2(0, 0)
	congratulations_sound.play()

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(win_label, "scale", Vector2(1, 1), 0.5)

	await get_tree().create_timer(3.0).timeout

	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
