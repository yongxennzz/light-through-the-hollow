extends Area2D

signal repair_requested(machine: Area2D)

var repaired := false

@onready var machine_visual: Sprite2D = $MachineVisual


func _ready() -> void:
	add_to_group("interactable")


func interact(_player: CharacterBody2D) -> void:
	if repaired:
		return

	repair_requested.emit(self)
	print("Generator interaction started")


func set_repaired() -> void:
	repaired = true
	machine_visual.modulate = Color(0.55, 1.0, 0.75, 1.0)
	print("Generator repaired")
