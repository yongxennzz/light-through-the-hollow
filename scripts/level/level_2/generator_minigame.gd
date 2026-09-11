extends Control

signal completed
signal failed

const LOOP_TEXTURE = preload(
	"res://assets/third_party/spritesheet/always appear and keep looping/spritesheet.png"
)
const SUCCESS_TEXTURE = preload(
	"res://assets/third_party/spritesheet/after success complete/spritesheet.png"
)
const FAILURE_TEXTURE = preload(
	"res://assets/third_party/spritesheet/after 1 fail hit/spritesheet.png"
)
const TEXT_ART = preload(
	"res://assets/images/ui/calibration/calibration_text_dark_fantasy.png"
)

const DIAL_RADIUS := 140.0
const LOOP_FPS := 12.0
const RESULT_FPS := 24.0

var active := false
var hits := 0
var needle_angle := -PI / 2.0
var needle_speed := 2.8
var target_angle := 0.0
var target_width := 0.8

var loop_time := 0.0
var result_time := 0.0
var showing_result := false
var result_success := false
var hit_flash_left := 0.0


func _ready() -> void:
	visible = false
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open() -> void:
	active = true
	hits = 0
	needle_angle = -PI / 2.0
	loop_time = 0.0
	result_time = 0.0
	showing_result = false
	hit_flash_left = 0.0

	_set_stage()
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	loop_time += delta
	hit_flash_left = maxf(hit_flash_left - delta, 0.0)

	if showing_result:
		result_time += delta

		var frame_count := 9 if result_success else 12
		var duration := float(frame_count) / RESULT_FPS

		if result_time >= duration:
			var succeeded := result_success
			close()

			if succeeded:
				completed.emit()
			else:
				failed.emit()

			return

	elif active:
		needle_angle = fposmod(
			needle_angle + needle_speed * delta,
			TAU
		)

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_SPACE:
			get_viewport().set_input_as_handled()

			# Ignore extra timing presses during result effects.
			if active:
				_try_hit()


func _try_hit() -> void:
	var difference := absf(
		wrapf(needle_angle - target_angle, -PI, PI)
	)

	if difference > target_width:
		_begin_result(false)
		return

	hits += 1
	hit_flash_left = 0.18

	if hits >= 3:
		_begin_result(true)
		return

	_set_stage()
	queue_redraw()


func _begin_result(succeeded: bool) -> void:
	active = false
	showing_result = true
	result_success = succeeded
	result_time = 0.0
	queue_redraw()


func _set_stage() -> void:
	var target_positions := [-2.2, 0.15, 2.2]
	var speeds := [2.5, 5.0, 8.0]
	var widths := [0.80, 0.48, 0.26]

	target_angle = target_positions[hits]
	needle_speed = speeds[hits]
	target_width = widths[hits]


func _draw() -> void:
	var panel_scale := 0.8
	var panel_size := Vector2(430, 510)
	var panel_position := Vector2(
		size.x - panel_size.x * panel_scale - 16.0,
		16.0
	)

	draw_set_transform(
		panel_position,
		0.0,
		Vector2(panel_scale, panel_scale)
	)

	var centre := Vector2(215, 220)

	# Permanent dial: the explosion animation fades between loops.
	draw_circle(
		centre,
		DIAL_RADIUS,
		Color(0.08, 0.12, 0.18, 1.0)
	)

	# Draw the looping artwork underneath the target and needle.
	if not showing_result:
		var loop_frame := int(loop_time * LOOP_FPS) % 10
		_draw_sheet_frame(
			LOOP_TEXTURE,
			loop_frame,
			96,
			centre,
			260.0,
			Color.WHITE
		)

	var ring_colour := Color(0.35, 0.45, 0.60, 1.0)

	if hit_flash_left > 0.0:
		ring_colour = Color(0.55, 1.0, 1.0, 1.0)

	draw_arc(
		centre, DIAL_RADIUS, 0.0, TAU,
		80, ring_colour, 5.0
	)

	# Keep the existing green target.
	draw_arc(
		centre,
		DIAL_RADIUS,
		target_angle - target_width,
		target_angle + target_width,
		32,
		Color(0.20, 1.0, 0.55, 1.0),
		18.0
	)

	# Keep the existing needle; freeze it during the result.
	var needle_end := centre + Vector2(
		cos(needle_angle), sin(needle_angle)
	) * (DIAL_RADIUS - 15.0)

	draw_line(
		centre, needle_end,
		Color(1.0, 0.82, 0.22, 1.0), 6.0
	)
	draw_circle(centre, 12.0, Color.WHITE)

	# Result effect appears over the frozen dial.
	if showing_result:
		var frame_count := 9 if result_success else 12
		var result_frame := mini(
			int(result_time * RESULT_FPS),
			frame_count - 1
		)
		var texture := SUCCESS_TEXTURE if result_success else FAILURE_TEXTURE

		_draw_sheet_frame(
			texture,
			result_frame,
			64,
			centre,
			240.0,
			Color.WHITE
		)

	_draw_text_art(0, Rect2(24, 24, 382, 42))

	var instruction_index := 1

	if showing_result:
		instruction_index = 6 if result_success else 7

	_draw_text_art(
		instruction_index,
		Rect2(24, 398, 382, 44)
	)

	_draw_text_art(
		2 + clampi(hits, 0, 3),
		Rect2(135, 451, 160, 36)
	)


func _draw_sheet_frame(
	texture: Texture2D,
	frame_index: int,
	cell_size: int,
	centre: Vector2,
	display_size: float,
	tint: Color
) -> void:
	var destination := Rect2(
		centre - Vector2.ONE * display_size * 0.5,
		Vector2.ONE * display_size
	)
	var source := Rect2(
		float(frame_index * cell_size),
		0.0,
		float(cell_size),
		float(cell_size)
	)

	draw_texture_rect_region(
		texture, destination, source, tint
	)


func close() -> void:
	active = false
	showing_result = false
	visible = false
	set_process(false)
	hits = 0
	result_time = 0.0
	hit_flash_left = 0.0

func _draw_text_art(index: int, destination: Rect2) -> void:
	# Regions match the generated image, including its uneven spacing.
	var regions: Array[Rect2] = [
		Rect2(0, 0, 1536, 128),
		Rect2(0, 128, 1536, 128),
		Rect2(500, 256, 540, 112),
		Rect2(500, 368, 540, 116),
		Rect2(500, 484, 540, 120),
		Rect2(500, 604, 540, 112),
		Rect2(0, 716, 1536, 140),
		Rect2(0, 856, 1536, 168)
	]

	draw_texture_rect_region(
		TEXT_ART,
		destination,
		regions[index]
	)
