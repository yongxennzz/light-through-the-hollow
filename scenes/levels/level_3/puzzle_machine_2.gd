extends Node2D
class_name PuzzleMachine2

@export var correct_sequence: Array[int] = [3, 2, 1, 4]  # answer
@export var ui_layer: CanvasLayer
@export var interact_area: Area2D
@export var digit_slots: Array[DigitSlot] = []
@export var power_button: TextureButton
@export var key: Area2D

var player_in_range: bool = false

func _ready() -> void:
	ui_layer.visible = false
	key.visible = false
	key.monitoring = false
	power_button.pressed.connect(_on_power_pressed)
	interact_area.body_entered.connect(_on_area_2d_body_entered)
	interact_area.body_exited.connect(_on_area_2d_body_exited)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		_toggle_ui()

func _toggle_ui() -> void:
	ui_layer.visible = not ui_layer.visible
	for guardian in get_tree().get_nodes_in_group("guardian"):
		guardian.alert_to_noise()

func _on_power_pressed() -> void:
	var player_input: Array[int] = []
	for slot in digit_slots:
		player_input.append(slot.current_value)
	if player_input == correct_sequence:
		_on_solved()

func _on_solved() -> void:
	key.visible = true
	key.monitoring = true
	ui_layer.visible = false
