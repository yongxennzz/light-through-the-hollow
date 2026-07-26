extends Area2D

@onready var machine_visual: ColorRect = $MachineVisual

var repaired := false


func interact(_player: CharacterBody2D) -> void:
	if repaired:
		return

	repaired = true
	machine_visual.color = Color.GREEN
	print("Test machine repaired")
