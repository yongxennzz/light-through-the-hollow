extends Area2D
 
@export var guardian: CharacterBody2D
@export var guardian_spawn: Marker2D
@export var zone_points: Array[Node2D] = []
 
 
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("zone_points size: ", zone_points.size())
		guardian.reset_to_zone(guardian_spawn.global_position, zone_points)
