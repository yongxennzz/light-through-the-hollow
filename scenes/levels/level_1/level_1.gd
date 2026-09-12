extends Node2D

@onready var win_panel = $WinCanvasLayer/Panel
@onready var congratulations_sound = $CongratulationsSound

func _ready() -> void:
	if not StoryState.intro_seen:
		var intro = preload("res://scenes/story/intro_dialogue.tscn").instantiate()
		add_child(intro)

func level_complete():
	win_panel.visible = true
	win_panel.scale = Vector2(0, 0)
	congratulations_sound.play()

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(win_panel, "scale", Vector2(1, 1), 0.5)

	await get_tree().create_timer(2.0).timeout

	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
