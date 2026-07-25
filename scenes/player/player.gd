extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

const MAX_HEALTH := 3
const WALK_SPEED := 180.0
const RUN_SPEED := 300.0
const DAMAGE_ESCAPE_SPEED := 450.0
const JUMP_VELOCITY := -420.0
const INVINCIBILITY_DURATION := 2.0

var health := MAX_HEALTH
var is_invincible := false
var invincibility_time_left := 0.0
var spawn_position := Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox

func _ready() -> void:
	spawn_position = global_position
	health_changed.emit(health, MAX_HEALTH)
	hurt_box.area_entered.connect(Callable(self, "_on_hurt_box_area_entered"))

func _physics_process(delta: float) -> void:
	if is_invincible:
		invincibility_time_left -= delta
		animated_sprite.modulate.a = 0.45 if int(invincibility_time_left * 10.0) % 2 == 0 else 1.0

		if invincibility_time_left <= 0.0:
			is_invincible = false
			animated_sprite.modulate.a = 1.0

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("drop_down") and is_on_floor():
		position.y += 16

	var direction := Input.get_axis("ui_left", "ui_right")

	if Input.is_key_pressed(KEY_A):
		direction = -1.0
	elif Input.is_key_pressed(KEY_D):
		direction = 1.0

	var is_running := Input.is_key_pressed(KEY_SHIFT)
	var current_speed := RUN_SPEED if is_running else WALK_SPEED

	if is_invincible:
		current_speed = maxf(current_speed, DAMAGE_ESCAPE_SPEED)

	if direction != 0:
		velocity.x = direction * current_speed
		animated_sprite.flip_h = direction > 0
		animated_sprite.play("run")
		animated_sprite.speed_scale = 1.5 if is_running else 0.75
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED * 8.0 * delta)
		animated_sprite.play("idle")
		animated_sprite.speed_scale = 1.0

	move_and_slide()


func take_damage(amount: int = 1) -> void:
	if is_invincible:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, MAX_HEALTH)

	if health <= 0:
		died.emit()
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
