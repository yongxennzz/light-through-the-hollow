extends CharacterBody2D

# ---------- 状态机 ----------
enum State { IDLE, PATROL, DISCOVER, CHASE, ATTACK, RETURNTOPATROL }
var state: State = State.PATROL

# ---------- Patrol 设置 ----------
@export var patrol_points: Array[Node2D] = []
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 140.0
@export var arrive_threshold: float = 6.0

var patrol_index: int = 0
var patrol_dir: int = -1
var patrol_waiting: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ---------- 追击 / 攻击 ----------
var target: Node2D = null
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

@export var discover_duration: float = 0.6
var discover_timer: float = 0.0

# ---------- 悬停晃动 ----------
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

	velocity = to_target.normalized() * chase_speed
	_face_direction(velocity.x)


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


# ---------- 跟丢玩家:找最近的巡逻点,回去继续巡逻 ----------
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


# ---------- 视野侦测----------
func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		state = State.DISCOVER


func _on_vision_area_body_exited(body: Node2D) -> void:
	if body == target:
		_lose_target()


# ---------- 共用: 面向移动方向 ----------
@onready var facing_root: Node2D = $FacingRoot

func _play_anim(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _face_direction(vx: float) -> void:
	if abs(vx) > 0.1:
		var facing_left := vx < 0
		sprite.flip_h = facing_left
		facing_root.scale.x = -1.0 if facing_left else 1.0


# ---------- 避障(可选) ----------
@onready var obstacle_check: RayCast2D = $FacingRoot/ObstacleCheck

func _avoid_obstacle(desired_velocity: Vector2) -> Vector2:
	if desired_velocity.length() < 0.01:
		return desired_velocity

	obstacle_check.target_position = desired_velocity.normalized() * 24
	obstacle_check.force_raycast_update()

	if obstacle_check.is_colliding():
		var normal := obstacle_check.get_collision_normal()
		return desired_velocity.slide(normal)

	return desired_velocity


# ---------- 切换区域 ----------
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
