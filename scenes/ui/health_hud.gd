extends CanvasLayer

@export var player: Node

@onready var health_bar: TextureProgressBar = $HealthBar


func _ready() -> void:
	if player == null:
		push_warning("HealthHUD: assign the Player.")
		return

	if not player.has_signal("health_changed"):
		push_warning("HealthHUD: Player needs health_changed.")
		return

	player.connect("health_changed", _update_health)

	_update_health(
		int(player.get("health")),
		int(player.get("max_health"))
	)


func _update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maxi(maximum, 1)
	health_bar.value = clampi(current, 0, maximum)
