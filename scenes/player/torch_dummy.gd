extends Area2D
@onready var dummy_visual: AnimatedSprite2D = $DummyVisual
var normal_color: Color
var stunned := false

func _ready() -> void:
	normal_color = dummy_visual.modulate

func stun() -> void:
	if stunned:
		return
	stunned = true
	dummy_visual.modulate = Color.YELLOW
	await get_tree().create_timer(3.0).timeout
	dummy_visual.modulate = normal_color
	stunned = false
