extends Node2D

@onready var interact_area: Area2D = $Area2D
@onready var machine_ui: CanvasLayer = $CanvasLayer
@onready var herb: Area2D = $Herb

var player_in_range := false


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	machine_ui.visible = false
	# Keep UI responsive even if the game gets paused later
	machine_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	machine_ui.connect("machine_solved", Callable(self, "_on_machine_solved"))
	herb.visible = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		# Could show an "Press E to interact" prompt here


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		_close_ui()
		machine_ui.call("reset_machine")


func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not machine_ui.visible:
		_open_ui()
	elif machine_ui.visible and event.is_action_pressed("ui_cancel"):
		_close_ui()


func _open_ui() -> void:
	machine_ui.visible = true
	for guardian in get_tree().get_nodes_in_group("guardian"):
		guardian.alert_to_noise()


func _close_ui() -> void:
	machine_ui.visible = false
	# get_tree().paused = false  # uncomment if pausing is added later


func _on_machine_solved() -> void:
	_close_ui()
	if not is_instance_valid(herb):
		return

	herb.visible = true
	var start_y := herb.position.y
	herb.position.y = start_y - 40
	herb.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(herb, "position:y", start_y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(herb, "modulate:a", 1.0, 0.2)
	tween.finished.connect(_on_herb_drop_finished)


func _on_herb_drop_finished() -> void:
	if is_instance_valid(herb):
		herb.call("activate")
