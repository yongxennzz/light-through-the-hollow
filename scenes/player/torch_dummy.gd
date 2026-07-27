extends Area2D

@onready var dummy_visual: AnimatedSprite2D = $DummyVisual

var normal_modulate: Color
var stunned := false


func _ready() -> void:
	normal_modulate = dummy_visual.modulate
	dummy_visual.play("idle")


func stun() -> void:
	if stunned:
		return

	stunned = true
	monitorable = false
	dummy_visual.modulate = Color(1.0, 1.0, 0.25, 1.0)

	await get_tree().create_timer(3.0).timeout

	monitorable = true
	dummy_visual.modulate = normal_modulate
	stunned = false
