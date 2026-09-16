extends Area2D
class_name Key

signal picked_up

@export var pickup_sound: AudioStreamPlayer2D

func _ready() -> void:
	add_to_group("key")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_pick_up()

func _pick_up() -> void:
	picked_up.emit()
	set_deferred("monitoring", false)
	visible = false
	
	if pickup_sound:
		pickup_sound.play()
		await pickup_sound.finished
	else:
		await get_tree().create_timer(0.1).timeout
	
	queue_free()
