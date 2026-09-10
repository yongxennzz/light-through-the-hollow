extends Area2D
# Chris — Animated noise-only trap. Never damages the player.

signal noise_emitted(world_position: Vector2, route_number: int)

@export_range(1, 4, 1) var route_number: int = 1
@export var rearm_delay: float = 3.0
@export var animation_frame_time: float = 0.1

@onready var trap_visual: Sprite2D = $TrapVisual

var cooldown_left := 0.0
var triggered := false
var elapsed := 0.0


func _ready() -> void:
	add_to_group("noise_traps")
	body_entered.connect(_on_body_entered)

	trap_visual.hframes = 4
	trap_visual.vframes = 1
	trap_visual.frame = 0


func _physics_process(delta: float) -> void:
	if not triggered:
		return

	elapsed += delta
	cooldown_left = maxf(cooldown_left - delta, 0.0)

	var frame_time := maxf(animation_frame_time, 0.01)
	var closing_duration := frame_time * 3.0

	if cooldown_left <= 0.0:
		# Fully open and ready again.
		triggered = false
		trap_visual.frame = 0
		return

	if elapsed < closing_duration:
		# Close: 0 → 1 → 2 → 3.
		trap_visual.frame = mini(int(elapsed / frame_time), 3)
	elif cooldown_left < closing_duration:
		# Reopen: 3 → 2 → 1 → 0.
		trap_visual.frame = clampi(
			int(ceil(cooldown_left / frame_time)), 0, 3
		)
	else:
		# Stay closed during the middle of the cooldown.
		trap_visual.frame = 3


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if triggered:
		return

	triggered = true
	elapsed = 0.0

	var minimum_cycle := maxf(animation_frame_time, 0.01) * 6.0
	cooldown_left = maxf(rearm_delay, minimum_cycle)

	noise_emitted.emit(global_position, route_number)
	print("Noise trap triggered on route ", route_number)
