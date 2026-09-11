extends CharacterBody2D
enum State {IDLE, PATROL, DISCOVER, CHASE, RETURNTOPATROL, ATTACK}
@export var gravity: float = 900.0
@export var vision_enabled: bool = true
@export var vision_range: float = 900.0

#chase
@export var chase_speed: float = 150.0

#attack
@export var attack_range: float = 450.0

#Patrol
@export var route_ab: Array[Node2D] = []  # PatrolA <-> PatrolB
@export var route_bc: Array[Node2D] = []  # PatrolB <-> PatrolC
@export var patrol_speed: float = 80.0
@export var patrol_wait_time: float = 1.5

var patrol_points: Array[Node2D] = []
var current_state: State = State.IDLE
var current_patrol_index: int = 0
var player: Node2D = null
var patrol_waiting: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_ray: RayCast2D = $VisionRayCast
@onready var damage_shape: CollisionShape2D = $PlayerDamageArea/CollisionShape2D


func _ready() -> void:
	patrol_points = route_ab
	call_deferred("_find_player")
	$PlayerDamageArea.add_to_group("damage_zone")
	damage_shape.disabled = true
	if not patrol_points.is_empty():
		current_state = State.PATROL
		sprite.play("PatrolIdle")
	else:
		current_state = State.IDLE
		sprite.play("PatrolIdle")
	print("Starting state: ", current_state, " | patrol_points count: ", patrol_points.size())

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	print("Player found: ", player)
	if player == null:
		push_warning("Guardian: No player found")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	update_vision()

	match current_state:
		State.IDLE:
			process_idle(delta)
		State.PATROL:
			process_patrol(delta)
		State.DISCOVER:
			process_discover(delta)
		State.CHASE:
			process_chase(delta)
		State.ATTACK:
			process_attack(delta)
		State.RETURNTOPATROL:
			process_return_to_patrol(delta)
	
	print("State: ", current_state, " | Animation: ", sprite.animation, " | Velocity.x: ", velocity.x)
	
	if current_state == State.ATTACK and sprite.animation == "Attack":
		damage_shape.disabled = not (sprite.frame in [4, 5])
	else:
		damage_shape.disabled = true
	move_and_slide()

func process_idle(delta: float) -> void:
	velocity.x = 0
	if sprite.animation != "PatrolIdle":
		sprite.play("PatrolIdle")

func update_vision() -> void:
	if not vision_enabled:
		return
	if player == null:
		return
	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player > vision_range:
		if current_state == State.CHASE:
			start_return_to_patrol()
			print("Player out of range -> Return to patrol")
		return

	vision_ray.target_position = vision_ray.to_local(player.global_position)
	vision_ray.force_raycast_update()
	var can_see_player = (
		vision_ray.is_colliding()
		and vision_ray.get_collider() == player
	)

	if can_see_player:
		if current_state == State.PATROL or current_state == State.IDLE:
			start_discover()
	else:
		if current_state == State.CHASE:
			print("Lost Player -> Return to patrol")
			start_return_to_patrol()

func process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity.x = 0
		return

	if patrol_waiting:
		velocity.x = 0
		return

	var target: Node2D = patrol_points[current_patrol_index]
	var horizontal_distance: float = abs(target.global_position.x - global_position.x)

	if horizontal_distance < 10.0 and is_on_floor():
		velocity.x = 0
		start_patrol_wait()
		return

	if sprite.animation != "PatrolRun":
		sprite.play("PatrolRun")

	var direction: float = sign(target.global_position.x - global_position.x)
	velocity.x = direction * patrol_speed
	sprite.flip_h = direction < 0

func start_patrol_wait() -> void:
	patrol_waiting = true
	sprite.play("PatrolIdle")
	await get_tree().create_timer(patrol_wait_time).timeout
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	patrol_waiting = false

func switch_patrol_route(new_route: Array[Node2D]) -> void:
	print("switch_patrol_route called | current_state before: ", current_state)
	patrol_points = new_route
	current_patrol_index = 0
	patrol_waiting = false


func process_chase(delta: float) -> void:
	if sprite.animation != "ChaseRun":
		sprite.play("ChaseRun")
	if player == null:
		velocity.x = 0
		return

	var horizontal_distance: float = abs(player.global_position.x - global_position.x)
	var direction: float = sign(player.global_position.x - global_position.x)
	print("Horizontal Distance: ", horizontal_distance, " | Direction: ", direction)

	if horizontal_distance <= attack_range:
		start_attack()
		return

	velocity.x = direction * chase_speed
	sprite.flip_h = direction < 0

func start_discover() -> void:
	current_state = State.DISCOVER
	if player != null:
		sprite.flip_h = player.global_position.x < global_position.x
	sprite.play("Discover")
	print("Player Detected -> Discover")
	await sprite.animation_finished
	if current_state == State.DISCOVER:
		current_state = State.CHASE
		print("Discover finished -> Chase")

func process_discover(delta: float) -> void:
	velocity.x = 0

func start_return_to_patrol() -> void:
	current_state = State.RETURNTOPATROL
	velocity.x = 0
	sprite.play("ReturnToPatrol")
	print("-> Return to Patrol")
	await sprite.animation_finished
	if current_state == State.RETURNTOPATROL:
		current_state = State.PATROL if not patrol_points.is_empty() else State.IDLE
		print("Return finished -> Patrol")

func process_return_to_patrol(delta: float) -> void:
	velocity.x = 0

func start_attack() -> void:
	current_state = State.ATTACK
	velocity.x = 0
	if player != null:
		sprite.flip_h = player.global_position.x < global_position.x
	sprite.play("Attack")
	print("In range -> Attack")
	await sprite.animation_finished
	if current_state == State.ATTACK:
		current_state = State.CHASE


func process_attack(delta: float) -> void:
	velocity.x = 0
