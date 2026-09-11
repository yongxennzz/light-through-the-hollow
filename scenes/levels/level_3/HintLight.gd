extends Node2D
class_name HintLight

@export var blink_count: int = 1        # 每次循环闪几下
@export var blink_interval: float = 1.0 # 每次闪烁之间的间隔
@export var pause_between_loops: float = 3.0  # 一轮闪完后,停顿多久再开始下一轮
@export var on_sprite: Sprite2D
@export var off_sprite: Sprite2D

func _ready() -> void:
	if on_sprite == null or off_sprite == null:
		push_error("HintLight '%s': on_sprite 或 off_sprite 没有在 Inspector 里赋值!" % name)
		return
	_set_lit(false)
	_start_loop()

func _start_loop() -> void:
	while true:
		await _blink_sequence()
		await get_tree().create_timer(pause_between_loops).timeout

func _blink_sequence() -> void:
	for i in range(blink_count):
		_set_lit(true)
		await get_tree().create_timer(0.15).timeout
		_set_lit(false)
		if i < blink_count - 1:
			await get_tree().create_timer(blink_interval).timeout

func _set_lit(is_lit: bool) -> void:
	on_sprite.visible = is_lit
	off_sprite.visible = not is_lit
