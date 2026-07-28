extends Node2D

@onready var win_label = $CanvasLayer/WinLabel
@onready var congratulations_sound = $CongratulationsSound

func level_complete():
	win_label.visible = true
	congratulations_sound.play()
	
	await get_tree().create_timer(3.0).timeout
	
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
