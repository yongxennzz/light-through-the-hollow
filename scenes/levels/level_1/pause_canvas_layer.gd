extends CanvasLayer

@onready var pause_button: Button = $PauseButton
@onready var pause_panel: Panel = $PausePanel
@onready var resume_button: Button = $PausePanel/ResumeButton
@onready var exit_button: Button = $PausePanel/ExitButton

func _ready() -> void:
	pause_panel.visible = false

	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_pause_pressed() -> void:
	pause_panel.visible = true
	get_tree().paused = true


func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_panel.visible = false


func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")
