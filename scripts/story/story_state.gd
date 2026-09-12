extends Node

# Session state: returning to the selector or respawning does not replay the intro.
# The main menu Start button begins a new run and resets these flags.
var intro_seen := false
var ending_started := false

func new_game() -> void:
	intro_seen = false
	ending_started = false

func finish_level_three() -> void:
	if ending_started:
		return
	ending_started = true
	# Safe from Area2D/physics callbacks. Call after the final escape succeeds.
	_open_ending.call_deferred()

func _open_ending() -> void:
	get_tree().paused = false
	var error := get_tree().change_scene_to_file("res://scenes/story/ending_dialogue.tscn")
	if error != OK:
		ending_started = false
		push_error("Could not open ending dialogue: %s" % error)
