extends Area2D

@onready var dummy_visual: ColorRect = $DummyVisual

var normal_color: Color
var stunned := false


func _ready() -> void:
	normal_color = dummy_visual.color


func stun() -> void:
	if stunned:
		return

	stunned = true
	dummy_visual.color = Color.YELLOW

	await get_tree().create_timer(3.0).timeout

	dummy_visual.color = normal_color
	stunned = false
