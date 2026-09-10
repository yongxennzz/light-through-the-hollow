extends Area2D

signal collected

var available := false
var was_collected := false

@onready var crystal_visual: AnimatedSprite2D = $CrystalVisual


func _ready() -> void:
	visible = false
	monitoring = false
	crystal_visual.play("glow")
	body_entered.connect(_on_body_entered)


func reveal() -> void:
	available = true
	visible = true
	monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if not available or was_collected:
		return

	if body.is_in_group("player"):
		was_collected = true
		available = false
		set_deferred("monitoring", false)
		visible = false
		collected.emit()
		print("Refinery Crystal collected")
