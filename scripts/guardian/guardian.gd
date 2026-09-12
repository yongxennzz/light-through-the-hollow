extends CharacterBody2D

enum State { IDLE, PATROL, DISCOVER, CHASE, ATTACK, RETURNTOPATROL }
var state: State = State.PATROL

# Patrol setting
@export var patrol_points: Array[Node2D] = []
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 140.0
@export var arrive_threshold: float = 6.0

var patrol_index: int = 0
var patrol_dir: int = -1
var patrol_waiting: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# chase/ attack
var target: Node2D = null
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

@export var discover_duration: float = 0.6
var discover_timer: float = 0.0

# tsop
@export var hover_amplitude: float = 4.0
@export var hover_speed: float = 2.0
var hover_time: float = 0.0
var debug_timer: float = 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group("guardian")


func alert_to_noise() -> void:
	if player_ref == null:
		player_ref = get_tree().get_first_node_in_group("player")
	if player_ref != null:
		target = player_ref
		state = State.DISCOVER
		print("Guardian alerted by noise!")


func _physics_process(delta: float) -> void:
	_is_illuminated()
	if illuminate_freeze_timer > 0.0:
		illuminate_freeze_timer -= delta
		velocity = Vector2.ZERO
		_play_anim("ChaseIdle")
		move_and_slide()
		if illuminate_freeze_timer <= 0.0:
			_lose_target()
		return

	hover_time += delta
	_check_vision()
	_check_noise()

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.PATROL:
			_do_patrol(delta)
			_play_anim("PatrolRun" if velocity.length() > 5.0 else "PatrolIdle")
		State.DISCOVER:
			velocity = Vector2.ZERO
			_play_anim("Discover")
			discover_timer += delta
			if discover_timer >= discover_duration:
				discover_timer = 0.0
				state = State.CHASE
		State.CHASE:
			_do_chase(delta)
			_play_anim("ChaseRun" if velocity.length() > 5.0 else "ChaseIdle")
		State.ATTACK:
			_do_attack(delta)
			_play_anim("Attack")
		State.RETURNTOPATROL:
			_do_patrol(delta)
			_play_anim("ReturnToPatrol")

	move_and_slide()


# ---------- PATROL ----------
func _do_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return

	var target_pos: Vector2 = patrol_points[patrol_index].global_position
	var to_target := target_pos - global_position

	if to_target.length() <= arrive_threshold:
		# 从 RETURNTOPATROL 回到最近点后,切回正常巡逻
		if state == State.RETURNTOPATROL:
			state = State.PATROL

		patrol_index += patrol_dir
		if patrol_index >= patrol_points.size() - 1:
			patrol_index = patrol_points.size() - 1
			patrol_dir = -1
		elif patrol_index <= 0:
			patrol_index = 0
			patrol_dir = 1
		return

	var move_dir := to_target.normalized()
	var hover_offset := sin(hover_time * hover_speed) * hover_amplitude
	velocity = move_dir * patrol_speed + Vector2(0, hover_offset)
	_face_direction(velocity.x)


# ---------- CHASE ----------
@export var give_up_distance: float = 2000.0
@export var lose_sight_grace: float = 1.0  # How long can the guardian continue based on memory after losing sight of the player
var lose_sight_timer: float = 0.0

func _do_chase(_delta: float) -> void:
	if target == null:
		_lose_target()
		return

	var to_target := target.global_position - global_position

	if to_target.length() > give_up_distance:
		_lose_target()
		return

	if to_target.length() <= attack_range:
		state = State.ATTACK
		velocity = Vector2.ZERO
		return

	if _has_line_of_sight(target):
		lose_sight_timer = 0.0
	else:
		lose_sight_timer += _delta
		if lose_sight_timer >= lose_sight_grace:
			_lose_target()
			return

	velocity = to_target.normalized() * chase_speed
	_face_direction(velocity.x)


func _has_line_of_sight(body: Node2D) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, body.global_position)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return result.collider == body

# ---------- ATTACK ----------
func _do_attack(delta: float) -> void:
	velocity = Vector2.ZERO

	if target == null:
		_lose_target()
		return

	var dist := target.global_position.distance_to(global_position)
	if dist > attack_range:
		state = State.CHASE
		return

	attack_timer += delta
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		_perform_attack()


func _perform_attack() -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(1)


# lose and find nearest patrol point
func _lose_target() -> void:
	target = null
	if patrol_points.is_empty():
		state = State.IDLE
		return

	var nearest_index := 0
	var nearest_dist := INF
	for i in patrol_points.size():
		var d := global_position.distance_to(patrol_points[i].global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_index = i

	patrol_index = nearest_index
	state = State.RETURNTOPATROL


@onready var vision_raycast: RayCast2D = $FacingRoot/VisionRayCast
@export var vision_length: float = 400.0
@export var noise_radius: float = 150.0
@onready var player_ref: Node2D = get_tree().get_first_node_in_group("player")

func _check_noise() -> void:
	if target != null or player_ref == null:
		return
	if player_ref.velocity.length() > 250.0:
		var dist := global_position.distance_to(player_ref.global_position)
		if dist <= noise_radius:
			target = player_ref
			state = State.DISCOVER


func _check_vision() -> void:
	vision_raycast.target_position = Vector2(vision_length, 0)
	vision_raycast.force_raycast_update()

	if vision_raycast.is_colliding():
		var body := vision_raycast.get_collider()
		if body.is_in_group("player") and target == null:
			target = body
			state = State.DISCOVER


# -vision detect
func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		state = State.DISCOVER


func _on_vision_area_body_exited(body: Node2D) -> void:
	if body == target:
		_lose_target()


# direction/facing
@onready var facing_root: Node2D = $FacingRoot

func _play_anim(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _face_direction(vx: float) -> void:
	if abs(vx) > 0.1:
		var facing_left := vx < 0
		sprite.flip_h = facing_left
		facing_root.scale.x = -1.0 if facing_left else 1.0

# change zon area
func reset_to_zone(new_position: Vector2, new_route: Array[Node2D]) -> void:
	visible = true
	velocity = Vector2.ZERO
	patrol_waiting = false
	target = null
	global_position = new_position
	patrol_points = new_route
	patrol_index = 0
	patrol_dir = -1
	if not patrol_points.is_empty():
		state = State.PATROL
		sprite.play("PatrolIdle")
	else:
		state = State.IDLE
		sprite.play("PatrolIdle")


# ---------- TORCH / STUN ----------
@export var illuminate_freeze_duration: float = 2.0  # 停顿多久,自己调
var illuminate_freeze_timer: float = 0.0

func _is_illuminated() -> bool:
	if player_ref == null:
		return false
	if not player_ref.torch_active:
		return false

	var to_guardian: Vector2 = global_position - player_ref.global_position
	var torch_range: float = 150.0
	var torch_angle_deg: float = 45.0

	if to_guardian.length() > torch_range:
		return false

	var facing_dir: Vector2 = Vector2.RIGHT if player_ref.facing_right else Vector2.LEFT
	var angle_to_guardian: float = rad_to_deg(facing_dir.angle_to(to_guardian))

	if abs(angle_to_guardian) <= torch_angle_deg:
		illuminate_freeze_timer = illuminate_freeze_duration
		return true

	return false
