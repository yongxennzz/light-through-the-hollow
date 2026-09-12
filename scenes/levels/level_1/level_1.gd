extends Node2D

@onready var win_panel = $WinCanvasLayer/Panel
@onready var congratulations_sound = $CongratulationsSound

@export var route: Array[Node2D] = []

func _ready() -> void:
	$Guardian.visible = false
	
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




func _on_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Guardian.reset_to_zone($GuardianPost.global_position, route)
		$Guardian.visible = true
