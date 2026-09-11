extends CharacterBody2D
# Chris — Level 2 patrol, bounded sight chase, contact attack and recovery.
@export var patrol_speed: float = 65.0
@export var chase_speed: float = 230.0
@export var detection_range: float = 260.0
@export var endpoint_pause: float = 0.5
@export var teleport_duration: float = 0.8
@export var stun_duration: float = 3.0
@export var stuck_timeout: float = 1.5
@export var noise_response_delay: float = 2.0
@export var investigation_wait: float = 2.0

@onready var guardian_visual: AnimatedSprite2D = $GuardianVisual
@onready var teleport_visual: AnimatedSprite2D = $TeleportVisual
@onready var routes: Node = $"../GuardianRoutes"
@onready var player: CharacterBody2D = $"../Player"
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var teleport_sound: AudioStreamPlayer2D = $TeleportSound

var route_index := 0
var heading_right := false
var patrol_stage := 0
var facing_direction := -1.0
var pause_left := 0.0
var teleport_left := 0.0
var stun_left := 0.0
var attack_left := 0.0
var attack_cooldown := 0.0
var target_x := 0.0
var chasing := false
var progress_time := 0.0
var progress_x := 0.0
var recovery_attempts := 0
var stun_receiver: Area2D
var pending_noise_route := -1
var pending_noise_position := Vector2.ZERO
var noise_time_left := 0.0

var investigating := false
var investigation_x := 0.0
var investigation_wait_left := 0.0


func _ready() -> void:
	# Exceptions are mutual: neither body can block or push the other.
	add_collision_exception_with(player)
	player.add_collision_exception_with(self)
	stun_receiver = Area2D.new()
	stun_receiver.name = "StunReceiver"
	stun_receiver.set_script(preload("res://scenes/levels/level_2/guardian_stun_receiver.gd"))
	stun_receiver.collision_layer = 1
	stun_receiver.collision_mask = 0
	stun_receiver.monitoring = false
	var shape_node := CollisionShape2D.new()
	shape_node.shape = $CollisionShape2D.shape.duplicate()
	shape_node.transform = $CollisionShape2D.transform
	stun_receiver.add_child(shape_node)
	add_child(stun_receiver)
	stun_receiver.add_to_group("stunnable")
	for route in routes.get_children():
		var crystal := route.get_node_or_null("Spawn/CrystalVisual")
		if crystal is AnimatedSprite2D:
			crystal.play("glow")
	for trap in $"../NoiseTraps".get_children():
		if trap.has_signal("noise_emitted"):
			trap.connect("noise_emitted", hear_noise)
	_enter_route(0)



func _enter_route(index: int) -> void:
	route_index = index % routes.get_child_count()
	var route := routes.get_child(route_index)
	global_position = route.get_node("Spawn").global_position
	attack_sound.stop()
	teleport_sound.play()
	target_x = route.get_node("LeftEnd").global_position.x
	velocity = Vector2.ZERO
	heading_right = false
	patrol_stage = 0
	facing_direction = -1.0
	guardian_visual.flip_h = true
	pause_left = 0.0
	stun_left = 0.0
	attack_left = 0.0
	attack_cooldown = 0.0
	chasing = false
	investigating = false
	guardian_visual.modulate = Color.WHITE
	guardian_visual.hide()
	teleport_visual.show()
	teleport_visual.stop()
	teleport_visual.play("appear")
	teleport_left = maxf(teleport_duration, 0.01)
	stun_receiver.set_deferred("monitorable", false)
	_reset_progress()
	_update_spawn_crystals()


func _physics_process(delta: float) -> void:
	
	if teleport_left > 0.0:
		teleport_left = maxf(teleport_left - delta, 0.0)
		if teleport_left == 0.0:
			teleport_visual.hide()
			guardian_visual.show()
			guardian_visual.play("idle")
			stun_receiver.set_deferred("monitorable", true)
		return

	var bounds := _route_bounds()
	var floor_y: float = routes.get_child(route_index).get_node("Spawn").global_position.y
	if global_position.x < bounds.x - 48.0 or global_position.x > bounds.y + 48.0 or absf(global_position.y - floor_y) > 96.0:
		_recover_route()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)

	if stun_left > 0.0:
		stun_left = maxf(stun_left - delta, 0.0)
		_wait_on_floor()
		if stun_left == 0.0:
			guardian_visual.modulate = Color.WHITE
		return
	if attack_left > 0.0:
		attack_left = maxf(attack_left - delta, 0.0)
		velocity.x = 0.0
		move_and_slide()
		_reset_progress()
		return

	chasing = _can_see_player()
	# Damage is independent of solid collision and works from either side.
	if attack_cooldown == 0.0 and _body_rect(self).intersects(_body_rect(player)):
		attack_cooldown = 0.8
		attack_left = 0.45
		guardian_visual.play("attack")


		attack_sound.play(2.0)

		player.take_damage(1)
		velocity.x = 0.0
		move_and_slide()
		_reset_progress()
		return
	if chasing:
		pause_left = 0.0
		investigating = false

		if pending_noise_route != -1:
			pending_noise_route = -1
			_update_spawn_crystals()

		_walk_toward(
			clampf(player.global_position.x, bounds.x, bounds.y),
			chase_speed,
			delta
		)
		return
	if pending_noise_route != -1:
		noise_time_left = maxf(noise_time_left - delta, 0.0)
		_wait_on_floor()

		if noise_time_left == 0.0:
			var destination_route := pending_noise_route
			var destination_position := pending_noise_position
			pending_noise_route = -1

			# Only teleport when the sound belongs to another route.
			if destination_route != route_index:
				_enter_route(destination_route)

			var investigation_bounds := _route_bounds()
			investigation_x = clampf(
				destination_position.x,
				investigation_bounds.x,
				investigation_bounds.y
			)

			investigating = true
			investigation_wait_left = investigation_wait
			pause_left = 0.0
			_update_spawn_crystals()

		return

	if investigating:
		if absf(global_position.x - investigation_x) > 2.0:
			_walk_toward(investigation_x, patrol_speed, delta)
		else:
			_wait_on_floor()
			investigation_wait_left = maxf(
				investigation_wait_left - delta, 0.0
			)

			if investigation_wait_left == 0.0:
				investigating = false

		return
	if pause_left > 0.0:
		pause_left = maxf(pause_left - delta, 0.0)
		_wait_on_floor()
		return
	if absf(target_x - global_position.x) <= 1.0:
		if patrol_stage == 0:
			# Reached the left end: walk across to the right.
			patrol_stage = 1
			heading_right = true
			target_x = bounds.y
			pause_left = endpoint_pause
			_wait_on_floor()

		elif patrol_stage == 1:
			# Reached the right end: return to the left.
			patrol_stage = 2
			heading_right = false
			target_x = bounds.x
			pause_left = endpoint_pause
			_wait_on_floor()

		else:
			# Finished the return trip: change patrol area.
			recovery_attempts = 0
			_enter_route(route_index + 1)

		return
	_walk_toward(target_x, patrol_speed, delta)


func _route_bounds() -> Vector2:
	var route := routes.get_child(route_index)
	var left: float = route.get_node("LeftEnd").global_position.x
	var right: float = route.get_node("RightEnd").global_position.x
	return Vector2(minf(left, right), maxf(left, right))


func _body_rect(body: CharacterBody2D) -> Rect2:
	var collision: CollisionShape2D = body.get_node("CollisionShape2D")
	var rectangle: RectangleShape2D = collision.shape
	var extent := rectangle.size * collision.global_scale.abs()
	return Rect2(collision.global_position - extent * 0.5, extent)


func _can_see_player() -> bool:
	var bounds := _route_bounds()
	var floor_y: float = routes.get_child(route_index).get_node("Spawn").global_position.y
	var player_rect := _body_rect(player)
	var player_feet := player_rect.end.y
	if player.global_position.x < bounds.x or player.global_position.x > bounds.y:
		return false
	if player_feet < floor_y - 64.0 or player_feet > floor_y + 24.0:
		return false
	var offset := player.global_position.x - global_position.x
	if absf(offset) > detection_range or offset * facing_direction < 0.0:
		return false
	var query := PhysicsRayQueryParameters2D.create(
		_body_rect(self).get_center(), player_rect.get_center(), 1,
		[get_rid(), player.get_rid()]
	)
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _walk_toward(destination: float, speed: float, delta: float) -> void:
	var distance := destination - global_position.x
	if absf(distance) <= 1.0:
		_wait_on_floor()
		return
	facing_direction = signf(distance)
	guardian_visual.flip_h = facing_direction < 0.0
	guardian_visual.play("walk")
	velocity.x = facing_direction * minf(speed, absf(distance) / delta)
	move_and_slide()
	progress_time += delta
	if progress_time >= maxf(stuck_timeout, 0.1):
		if absf(global_position.x - progress_x) < 8.0:
			_recover_route()
		else:
			recovery_attempts = 0
			_reset_progress()


func _wait_on_floor() -> void:
	velocity.x = 0.0
	guardian_visual.play("idle")
	move_and_slide()
	_reset_progress()


func _reset_progress() -> void:
	progress_time = 0.0
	progress_x = global_position.x


func _recover_route() -> void:
	recovery_attempts += 1
	print("Guardian recovery: route ", route_index + 1)
	if recovery_attempts >= 2:
		recovery_attempts = 0
		_enter_route(route_index + 1)
	else:
		_enter_route(route_index)


func stun() -> void:
	if teleport_left > 0.0 or stun_left > 0.0:
		return
	stun_left = stun_duration
	attack_sound.stop()
	attack_left = 0.0
	chasing = false
	velocity.x = 0.0
	guardian_visual.modulate = Color(1.0, 1.0, 0.25)
	_reset_progress()

func hear_noise(world_position: Vector2, route_number: int) -> void:
	var index := route_number - 1

	if index < 0 or index >= routes.get_child_count():
		return

	# A visible player takes priority over a trap.
	if chasing:
		return

	# Keep the first pending alert so repeated traps cannot
	# continually restart the countdown.
	if pending_noise_route != -1:
		return

	pending_noise_route = index
	pending_noise_position = world_position
	noise_time_left = noise_response_delay
	investigating = false
	_update_spawn_crystals()

	print("Guardian heard trap: route ", route_number)


func _update_spawn_crystals() -> void:
	var next_index := (route_index + 1) % routes.get_child_count()

	if pending_noise_route != -1:
		next_index = pending_noise_route

	for index in range(routes.get_child_count()):
		var crystal := routes.get_child(index).get_node_or_null(
			"Spawn/CrystalVisual"
		)

		if crystal is AnimatedSprite2D:
			# Change this node's speed, not the shared animation resource.
			crystal.speed_scale = 2.0 if index == next_index else 1.0
