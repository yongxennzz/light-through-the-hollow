extends Area2D
@export var min_x: float = 1500.0
@export var max_x: float = 1800.0
@export var move_duration: float = 2.0

func _ready():
	add_to_group("damage_zone", true)
	print("is in damage_zone: ", is_in_group("damage_zone"))
	move_loop()

func move_loop():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "global_position:x", max_x, move_duration)
	tween.tween_property(self, "global_position:x", min_x, move_duration)
