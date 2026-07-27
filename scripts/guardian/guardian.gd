extends CharacterBody2D

## Guardian AI — Milestone 1

enum State { PATROL, CHASE, STUNNED, RETURN_TO_PATROL }

# Exported tuning variables (can adjust these during playtest)
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 100.0
@export var jump_velocity: float = -300.0
@export var stun_duration: float = 5.5
@export var vision_enabled: bool = true
@export var gravity: float = 900.0
@export var lose_sight_delay: float = 1.5  # seconds players hidden before giving up chase
@export var patrol_points: Array[Node2D] = []

var current_state: State = State.PATROL
var current_patrol_index: int = 0
var facing_direction: int = 1
var player: Node2D = null

#get ready
@onready var sprite: Sprite2D = $Sprite2D
@onready var vision_ray: RayCast2D = $VisionRayCast
@onready var player_damage_area: Area2D = $PlayerDamageArea
@onready var torch_hurtbox: Area2D = $TorchHurtArea
@onready var stun_timer: Timer = $StunTimer
@onready var detection_timer: Timer = $DetectionTimer


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("Guardian: no node found in group 'player'.")

	player_damage_area.add_to_group("damage_zone")
	
	stun_timer.one_shot = true
	stun_timer.wait_time = stun_duration
	stun_timer.timeout.connect(_on_stun_timer_timeout)

	detection_timer.one_shot = true
	detection_timer.wait_time = lose_sight_delay
	detection_timer.timeout.connect(_on_detection_timer_timeout)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	_update_vision()

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.STUNNED:
			_process_stunned(delta)
		State.RETURN_TO_PATROL:
			_process_return_to_patrol(delta)

	move_and_slide()


# Vision
func _update_vision() -> void:
	if not vision_enabled or player == null or current_state == State.STUNNED:
		return

	vision_ray.target_position = player.global_position - global_position
	vision_ray.force_raycast_update()

	var can_see_player: bool = vision_ray.is_colliding() and vision_ray.get_collider() == player

	if can_see_player:
		detection_timer.stop()
		if current_state == State.PATROL or current_state == State.RETURN_TO_PATROL:
			current_state = State.CHASE
	else:
		if current_state == State.CHASE and detection_timer.is_stopped():
			detection_timer.start()


func _on_detection_timer_timeout() -> void:
	if current_state == State.CHASE:
		current_state = State.RETURN_TO_PATROL


# Patrol
func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	var target: Node2D = patrol_points[current_patrol_index]
	_move_toward_x(target.global_position, patrol_speed)
	_jump_if_needed(target.global_position)

	if abs(global_position.x - target.global_position.x) < 4.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()


# Chase
func _process_chase(delta: float) -> void:
	if player == null:
		current_state = State.PATROL
		return

	_move_toward_x(player.global_position, chase_speed)
	_jump_if_needed(player.global_position)


# Stunned
func _process_stunned(delta: float) -> void:
	velocity.x = 0
	# gravity above still applies; only horizontal movement is frozen


func stun() -> void:
	if current_state == State.STUNNED:
		return  # don't reset an active stun
	current_state = State.STUNNED
	velocity.x = 0
	stun_timer.start()
	player_damage_area.monitorable = false  # can't damage player while stunned
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 1.0)  # placeholder stunned tint


func _on_stun_timer_timeout() -> void:
	player_damage_area.monitorable = true
	if sprite:
		sprite.modulate = Color(1, 1, 1)
	if player != null and vision_enabled:
		vision_ray.target_position = player.global_position - global_position
		vision_ray.force_raycast_update()
		if vision_ray.is_colliding() and vision_ray.get_collider() == player:
			current_state = State.CHASE
			return
	current_state = State.RETURN_TO_PATROL


# Return to patrol
func _process_return_to_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		current_state = State.PATROL
		return

	var nearest_index: int = _nearest_patrol_index()
	var target: Node2D = patrol_points[nearest_index]
	_move_toward_x(target.global_position, patrol_speed)
	_jump_if_needed(target.global_position)

	if abs(global_position.x - target.global_position.x) < 4.0:
		current_patrol_index = nearest_index
		current_state = State.PATROL


func _nearest_patrol_index() -> int:
	var closest_index: int = 0
	var closest_dist: float = INF
	for i in patrol_points.size():
		var dist: float = global_position.distance_to(patrol_points[i].global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_index = i
	return closest_index


#Shared movement helpers
func _move_toward_x(target_pos: Vector2, speed: float) -> void:
	var dx: float = target_pos.x - global_position.x
	if abs(dx) < 2.0:
		velocity.x = 0
		return
	facing_direction = 1 if dx > 0 else -1
	velocity.x = facing_direction * speed
	if sprite:
		sprite.flip_h = facing_direction < 0


func _jump_if_needed(target_pos: Vector2) -> void:
	# M1 simple jump: on floor, and target is meaningfully above us
	# (small platform gap/ledge). No pathfinding — just a fixed jump.
	if is_on_floor() and target_pos.y < global_position.y - 16.0:
		velocity.y = jump_velocity
