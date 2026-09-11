extends Node2D
# Chris — Level 2 machine progression and puzzle integration.
static var intro_seen := false
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
var menu_music_was_paused := false
var menu_music_previous_process_mode: int = Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	menu_music_was_paused = MenuMusic.stream_paused
	menu_music_previous_process_mode = MenuMusic.process_mode

	# Prevent the intro's pause/unpause from restarting menu music.
	MenuMusic.process_mode = Node.PROCESS_MODE_ALWAYS
	MenuMusic.stream_paused = true
	_pause_menu_music_after_startup()
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

	if not intro_seen:
		intro_seen = true
		$LevelIntro.show_intro()
		await $LevelIntro.dismissed

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
	player.block_jump_until_release()
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
	if current_health < previous_health:
		_play_level_sound(&"PlayerHurtSound")

		if active_machine != null:
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
	_play_level_sound(&"CollectSound")
	portal_exit.activate()
	_play_level_sound(&"ExitPortalSound")
	print("Crystal collected. Exit portal activated.")


func _on_portal_entered() -> void:
	$LevelAudio/ExitPortalSound.stop()
	_play_level_sound(&"LevelCompleteSound")
	print("Level 2 complete")

func _show_entrance_portal() -> void:
	var entrance: AnimatedSprite2D = $Gameplay/EntrancePortal

	entrance.show()
	entrance.play("active")
	_play_level_sound(&"EntrancePortalSound")

	await get_tree().create_timer(2.0, false).timeout
	$LevelAudio/EntrancePortalSound.stop()
	if is_instance_valid(entrance):
		entrance.hide()

func _exit_tree() -> void:
	if is_instance_valid(MenuMusic):
		MenuMusic.process_mode = menu_music_previous_process_mode
		MenuMusic.stream_paused = menu_music_was_paused

	if not restarting:
		intro_seen = false
func _pause_menu_music_after_startup() -> void:
	await get_tree().process_frame

	if is_instance_valid(MenuMusic):
		MenuMusic.stream_paused = true

func _play_level_sound(sound_name: StringName) -> void:
	var sound := $LevelAudio.get_node_or_null(
		NodePath(String(sound_name))
	) as AudioStreamPlayer

	if sound != null and sound.stream != null:
		sound.play()
