extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal player_died
signal torch_ready
signal torch_cooldown_started(cooldown_seconds: float)

const MAX_HEALTH := 3
const WALK_SPEED := 180.0
const RUN_SPEED := 300.0
const DAMAGE_ESCAPE_SPEED := 450.0
const JUMP_VELOCITY := -420.0
const INVINCIBILITY_DURATION := 2.0

const TORCH_FLASH_DURATION := 0.25
const TORCH_COOLDOWN_DURATION := 3.0

var health := MAX_HEALTH
var is_invincible := false
var invincibility_time_left := 0.0
var spawn_position := Vector2.ZERO
var nearby_interactables: Array[Area2D] = []

var facing_right := true
var torch_active := false
var torch_flash_time_left := 0.0
var torch_cooldown_time_left := 0.0
var controls_locked := false
var recoil_time_left := 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var torch_zone: Area2D = $TorchZone
@onready var flashlight: Sprite2D = $Flashlight
@onready var interaction_zone: Area2D = $InteractionZone


func _ready() -> void:
	spawn_position = global_position
	health_changed.emit(health, MAX_HEALTH)

	hurt_box.area_entered.connect(Callable(self, "_on_hurt_box_area_entered"))
	torch_zone.area_entered.connect(Callable(self, "_on_torch_zone_area_entered"))
	interaction_zone.area_entered.connect(Callable(self, "_on_interaction_zone_area_entered"))
	interaction_zone.area_exited.connect(Callable(self, "_on_interaction_zone_area_exited"))

	torch_zone.monitoring = false
	flashlight.visible = false


func _physics_process(delta: float) -> void:
	_update_torch(delta)
	
	if recoil_time_left > 0.0:
		recoil_time_left -= delta

	if not is_on_floor():
		velocity += get_gravity() * delta

		move_and_slide()
		return
		
	if controls_locked:
		velocity.x = 0.0

		if not is_on_floor():
			velocity += get_gravity() * delta

		move_and_slide()
		return
		
	if is_invincible:
		invincibility_time_left -= delta
		animated_sprite.modulate.a = 0.45 if int(invincibility_time_left * 10.0) % 2 == 0 else 1.0

		if invincibility_time_left <= 0.0:
			is_invincible = false
			animated_sprite.modulate.a = 1.0

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("drop_down") and is_on_floor():
		position.y += 16

	if Input.is_action_just_pressed("torchlight"):
		use_torch()

	if Input.is_action_just_pressed("interact") and not torch_active:
		interact_with_nearest()

	var direction := Input.get_axis("move_left", "move_right")
	var is_running := Input.is_action_pressed("run")
	var current_speed := RUN_SPEED if is_running else WALK_SPEED

	if is_invincible:
		current_speed = maxf(current_speed, DAMAGE_ESCAPE_SPEED)

	if direction != 0:
		facing_right = direction > 0
		_update_facing_direction()

		velocity.x = direction * current_speed
		animated_sprite.play("run")
		animated_sprite.speed_scale = 1.5 if is_running else 0.75
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED * 8.0 * delta)
		animated_sprite.play("idle")
		animated_sprite.speed_scale = 1.0

	move_and_slide()


func _update_facing_direction() -> void:
	animated_sprite.flip_h = facing_right
	torch_zone.position.x = 120.0 if facing_right else -120.0
	flashlight.position.x = 45.0 if facing_right else -45.0
	flashlight.flip_h = not facing_right


func use_torch() -> void:
	if torch_cooldown_time_left > 0.0:
		return

	torch_active = true
	torch_flash_time_left = TORCH_FLASH_DURATION
	torch_cooldown_time_left = TORCH_COOLDOWN_DURATION

	flashlight.visible = true
	torch_zone.monitoring = true
	torch_cooldown_started.emit(TORCH_COOLDOWN_DURATION)


func _update_torch(delta: float) -> void:
	if torch_flash_time_left > 0.0:
		torch_flash_time_left -= delta

		if torch_flash_time_left <= 0.0:
			torch_active = false
			flashlight.visible = false
			torch_zone.monitoring = false

	if torch_cooldown_time_left > 0.0:
		torch_cooldown_time_left = maxf(torch_cooldown_time_left - delta, 0.0)

		if torch_cooldown_time_left <= 0.0:
			torch_ready.emit()

func take_damage(amount: int = 1) -> void:
	if is_invincible:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)

	if health <= 0:
		player_died.emit()
		reset_for_level()
		return

	is_invincible = true
	invincibility_time_left = INVINCIBILITY_DURATION


func reset_for_level() -> void:
	health = MAX_HEALTH
	is_invincible = false
	invincibility_time_left = 0.0
	animated_sprite.modulate.a = 1.0
	global_position = spawn_position
	velocity = Vector2.ZERO
	health_changed.emit(health, MAX_HEALTH)


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("damage_zone"):
		take_damage()


func _on_torch_zone_area_entered(area: Area2D) -> void:
	if torch_active and area.is_in_group("stunnable") and area.has_method("stun"):
		area.stun()


func interact_with_nearest() -> void:
	var closest_interactable: Area2D = null
	var closest_distance := INF

	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue

		var distance := global_position.distance_to(interactable.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_interactable = interactable

	if closest_interactable != null and closest_interactable.has_method("interact"):
		closest_interactable.interact(self)


func _on_interaction_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") and area not in nearby_interactables:
		nearby_interactables.append(area)


func _on_interaction_zone_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)

func set_controls_locked(locked: bool) -> void:
	controls_locked = locked

	if locked:
		velocity.x = 0.0
		
func push_back_from(source_position: Vector2) -> void:
	var direction := signf(global_position.x - source_position.x)

	if direction == 0.0:
		direction = -1.0

	velocity = Vector2(direction * 420.0, -180.0)
	recoil_time_left = 0.25
