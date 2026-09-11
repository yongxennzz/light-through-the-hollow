extends AudioStreamPlayer2D

@export var walking_pitch: float = 1.0
@export var chasing_pitch: float = 1.25

@onready var guardian = get_parent()


func _process(_delta: float) -> void:
	var can_play: bool = (
		guardian.teleport_left <= 0.0
		and guardian.stun_left <= 0.0
		and guardian.attack_left <= 0.0
		and guardian.is_on_floor()
		and absf(guardian.get_real_velocity().x) > 5.0
	)

	if not can_play:
		if playing:
			stop()
		return

	pitch_scale = chasing_pitch if guardian.chasing else walking_pitch

	# Start once, then let the recording continue.
	if not playing:
		play()
