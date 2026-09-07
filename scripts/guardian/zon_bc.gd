extends Area2D
@export var guardian: CharacterBody2D
@export var target_route: String = "bc"

func _on_area_entered(area: Area2D) -> void:
	print("ZonBC entered by area: ", area.name)
	if area.get_parent().is_in_group("player"):
		if target_route == "bc":
			guardian.switch_patrol_route(guardian.route_bc)
		else:
			guardian.switch_patrol_route(guardian.route_ab)
pass
