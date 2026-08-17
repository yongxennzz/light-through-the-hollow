extends Node2D

@onready var player: CharacterBody2D = $Gameplay/Player
@onready var generator: Area2D = $Gameplay/Objectives/GeneratorMachine
@onready var calibration_game = $GeneratorMinigameUI/CalibrationGame
@onready var refinery_crystal: Area2D = $Gameplay/Objectives/RefineryCrystal
@onready var portal_exit: Area2D = $Gameplay/Objectives/PortalExit

func _ready() -> void:
	generator.repair_requested.connect(_on_generator_repair_requested)
	calibration_game.completed.connect(_on_calibration_completed)
	calibration_game.failed.connect(_on_calibration_failed)
	refinery_crystal.collected.connect(_on_refinery_crystal_collected)
	portal_exit.entered.connect(_on_portal_entered)
	
func _on_generator_repair_requested(_machine: Area2D) -> void:
	player.set_controls_locked(true)
	calibration_game.open()


func _on_calibration_completed() -> void:
	player.set_controls_locked(false)
	generator.set_repaired()
	refinery_crystal.reveal()
	print("Level 2 generator repaired")

func _on_calibration_failed() -> void:
	player.set_controls_locked(false)
	player.push_back_from(generator.global_position)
	print("Generator calibration failed")

func _on_refinery_crystal_collected() -> void:
	portal_exit.activate()
	print("Level 2 material collected: portal activated")

func _on_portal_entered() -> void:
	print("Level 2 complete")
