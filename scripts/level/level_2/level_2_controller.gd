extends Node2D
# Chris — Level 2 machine progression and puzzle integration.

@export var machine_start_distance: float = 64.0
@export var machine_cancel_distance: float = 96.0

@onready var player = $Gameplay/Player
@onready var calibration_game = $GeneratorMinigameUI/CalibrationGame
@onready var refinery_crystal = $Gameplay/Objectives/RefineryCrystal
@onready var portal_exit = $Gameplay/Objectives/PortalExit

var machines: Array = []
var active_machine = null
var repaired_count := 0
var previous_health := 3
var restarting := false


func _ready() -> void:
	machines = [
		$Gameplay/Objectives/GeneratorMachine,
		$Gameplay/Objectives/GeneratorMachine2,
		$Gameplay/Objectives/GeneratorMachine3
	]

	for machine in machines:
		machine.repair_requested.connect(
			_on_generator_repair_requested
		)

	calibration_game.completed.connect(_on_calibration_completed)
	calibration_game.failed.connect(_on_calibration_failed)
	refinery_crystal.collected.connect(_on_refinery_crystal_collected)
	portal_exit.entered.connect(_on_portal_entered)

	previous_health = player.health
	player.health_changed.connect(_on_health_changed)
	player.player_died.connect(_on_player_died)

	player.machine_minigame_active = false
	_show_entrance_portal()


func _physics_process(_delta: float) -> void:
	if active_machine == null:
		return

	var distance: float = player.global_position.distance_to(
		active_machine.global_position
	)

	if distance > machine_cancel_distance:
		_cancel_calibration()
		print("Repair cancelled: moved away")


func _on_generator_repair_requested(machine: Area2D) -> void:
	if restarting or active_machine != null:
		return

	if machine.repaired:
		return

	var distance: float = player.global_position.distance_to(
		machine.global_position
	)

	if distance > machine_start_distance:
		print("Move closer to the machine")
		return

	active_machine = machine
	player.machine_minigame_active = true
	calibration_game.open()


func _cancel_calibration() -> void:
	calibration_game.close()
	player.machine_minigame_active = false
	active_machine = null


func _on_calibration_completed() -> void:
	if active_machine == null or restarting:
		return

	# Recheck distance before accepting the final hit.
	if player.global_position.distance_to(
		active_machine.global_position
	) > machine_cancel_distance:
		_cancel_calibration()
		return

	var finished_machine = active_machine
	_cancel_calibration()

	finished_machine.set_repaired()
	repaired_count += 1
	print("Machines repaired: %d / 3" % repaired_count)

	if repaired_count == machines.size():
		refinery_crystal.reveal()
		print("All machines repaired. Collect the exit crystal.")


func _on_calibration_failed() -> void:
	if active_machine == null:
		return

	var source_position: Vector2 = active_machine.global_position
	_cancel_calibration()
	player.push_back_from(source_position)
	print("Timing missed: retry the machine")


func _on_health_changed(current_health: int, _maximum: int) -> void:
	if current_health < previous_health and active_machine != null:
		_cancel_calibration()
		print("Repair interrupted by damage")

	previous_health = current_health


func _on_player_died() -> void:
	if restarting:
		return

	restarting = true
	_cancel_calibration()
	call_deferred("_restart_level")


func _restart_level() -> void:
	get_tree().reload_current_scene()


func _on_refinery_crystal_collected() -> void:
	portal_exit.activate()
	print("Crystal collected. Exit portal activated.")


func _on_portal_entered() -> void:
	print("Level 2 complete")

func _show_entrance_portal() -> void:
	var entrance: AnimatedSprite2D = $Gameplay/EntrancePortal

	entrance.show()
	entrance.play("active")

	await get_tree().create_timer(2.0, false).timeout

	if is_instance_valid(entrance):
		entrance.hide()
