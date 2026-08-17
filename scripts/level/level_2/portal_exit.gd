extends Area2D

signal entered

var active := false

@onready var portal_visual: AnimatedSprite2D = $PortalVisual


func _ready() -> void:
	visible = false
	monitoring = false
	portal_visual.play("active")
	body_entered.connect(_on_body_entered)


func activate() -> void:
	active = true
	visible = true
	monitoring = true
	print("Level 2 portal activated")


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return

	if body is CharacterBody2D:
		monitoring = false
		entered.emit()
