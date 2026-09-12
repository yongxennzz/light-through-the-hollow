extends Node2D
class_name Door

@export var key: Key
@export var herb: Herb
@export var sprite_closed: Sprite2D
@export var sprite_open: Sprite2D
@export var exit_zone: Area2D

var has_key: bool = false
var has_herb: bool = false
var is_open: bool = false

func _ready() -> void:

	key.picked_up.connect(_on_key_picked_up)
	herb.picked_up.connect(_on_herb_picked_up)
	exit_zone.body_entered.connect(_on_exit_zone_entered)

	_update_door_visual()

func _on_key_picked_up() -> void:
	has_key = true
	_check_unlock()

func _on_herb_picked_up() -> void:
	has_herb = true
	_check_unlock()

func _check_unlock() -> void:
	if has_key and has_herb:
		is_open = true
		_update_door_visual()

func _update_door_visual() -> void:
	sprite_open.visible = is_open
	sprite_closed.visible = not is_open

func _on_exit_zone_entered(body: Node2D) -> void:
	if is_open and body.is_in_group("player"):
		_go_to_main_menu()

func _go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn") 
