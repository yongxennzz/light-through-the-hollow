extends Node2D

func _ready():
	$Player/Camera2D.limit_left = -112
	$Player/Camera2D.limit_right = 2112
	$Player/Camera2D.limit_top = -80
	$Player/Camera2D.limit_bottom = 1408
	MenuMusic.stop()

@export var route_a: Array[Node2D] = []
@export var route_b: Array[Node2D] = []
 
 
func _on_zon_a_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Guardian.reset_to_zone($GuardianPostA.global_position, route_a)
		$Guardian.visible = true
 
func _on_zon_b_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Guardian.reset_to_zone($GuardianPostB.global_position, route_b)
		$Guardian.visible = true
 
