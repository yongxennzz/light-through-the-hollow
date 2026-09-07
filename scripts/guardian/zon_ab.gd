extends Area2D

@export var guardian: CharacterBody2D
@export var target_route: String = "ab"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if target_route == "ab":
			guardian.switch_patrol_route(guardian.route_ab)
		else:
			guardian.switch_patrol_route(guardian.route_bc)
pass
