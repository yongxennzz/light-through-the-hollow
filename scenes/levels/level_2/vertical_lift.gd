extends Node2D
# Chris — Level 2 vertical lift.
# Moves between fixed endpoints and pauses at each stop.

@export_range(1.0, 300.0, 1.0) var travel_speed: float = 80.0
@export_range(0.0, 5.0, 0.1) var endpoint_pause: float = 0.5

@onready var platform_body: AnimatableBody2D = $PlatformBody
@onready var top_stop: Marker2D = $TopStop
@onready var bottom_stop: Marker2D = $BottomStop

var movement_tween: Tween


func _ready() -> void:
	platform_body.position = bottom_stop.position

	var travel_distance := top_stop.position.distance_to(
		bottom_stop.position
	)

	if travel_distance <= 0.0:
		push_warning("Lift endpoints must be different.")
		return

	var travel_time := travel_distance / travel_speed

	movement_tween = create_tween()
	movement_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	movement_tween.set_trans(Tween.TRANS_LINEAR)
	movement_tween.set_loops()

	movement_tween.tween_interval(endpoint_pause)
	movement_tween.tween_property(
		platform_body,
		"position",
		top_stop.position,
		travel_time
	)

	movement_tween.tween_interval(endpoint_pause)
	movement_tween.tween_property(
		platform_body,
		"position",
		bottom_stop.position,
		travel_time
	)
