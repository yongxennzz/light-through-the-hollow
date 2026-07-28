extends HBoxContainer

@onready var player = $"../../Player"
@onready var health_label = $HealthLabel


func _ready():
	player.health_changed.connect(update_health)
	update_health(player.health, player.MAX_HEALTH)


func update_health(current_health, max_health):
	health_label.text = "Heart x" + str(current_health)
