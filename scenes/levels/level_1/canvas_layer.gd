extends CanvasLayer

@onready var health_container: HBoxContainer = $HealthContainer

var heart_list: Array[TextureRect] = []

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")

	if player:
		player.health_changed.connect(_on_health_changed)

		for child in health_container.get_children():
			if child is TextureRect:
				heart_list.append(child)

		_on_health_changed(player.health, player.MAX_HEALTH)


func _on_health_changed(current_health: int, max_health: int) -> void:
	for i in range(heart_list.size()):
		heart_list[i].visible = i < current_health
