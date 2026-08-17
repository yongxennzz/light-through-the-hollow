extends CanvasLayer

@onready var health_label: Label = $HealthLabel

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.health, player.MAX_HEALTH)

func _on_health_changed(current_health: int, max_health: int) -> void:
	health_label.text = "x" + str(current_health)
