extends Area2D

signal repair_requested(machine: Area2D)

@export var float_height: float = 2.0
@export var float_speed: float = 2.0
@export var repaired_pulse_amount: float = 0.04

var repaired := false
var animation_time := 0.0
var original_position := Vector2.ZERO
var original_scale := Vector2.ONE

@onready var machine_visual: Sprite2D = $MachineVisual


func _ready() -> void:
	add_to_group("interactable")

	original_position = machine_visual.position
	original_scale = machine_visual.scale

	# Keep the three machines from moving in perfect synchronisation.
	animation_time = randf() * TAU


func _process(delta: float) -> void:
	animation_time += delta

	var speed := float_speed * (1.5 if repaired else 1.0)
	var wave := sin(animation_time * speed)

	machine_visual.position = original_position + Vector2(
		0.0, wave * float_height
	)

	if repaired:
		var pulse := 1.0 + wave * repaired_pulse_amount
		machine_visual.scale = original_scale * pulse
	else:
		machine_visual.scale = original_scale


func interact(_player: CharacterBody2D) -> void:
	if repaired:
		return

	repair_requested.emit(self)
	print("Generator interaction started")


func set_repaired() -> void:
	if repaired:
		return

	repaired = true
	machine_visual.modulate = Color(0.55, 1.0, 0.75, 1.0)
	print("Generator repaired")
