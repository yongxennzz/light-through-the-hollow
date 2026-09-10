extends Control

signal completed
signal failed

var active := false
var hits := 0
var needle_angle := -PI / 2.0
var needle_speed := 2.8
var target_angle := 0.0
var target_width := 0.8

const DIAL_RADIUS := 140.0


func _ready() -> void:
	visible = false
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open() -> void:
	active = true
	hits = 0
	needle_angle = -PI / 2.0
	_set_stage()
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	needle_angle = fposmod(needle_angle + needle_speed * delta, TAU)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_try_hit()


func _try_hit() -> void:
	var difference := absf(wrapf(needle_angle - target_angle, -PI, PI))

	if difference > target_width:
		active = false
		visible = false
		set_process(false)
		failed.emit()
		return

	hits += 1

	if hits >= 3:
		active = false
		visible = false
		set_process(false)
		completed.emit()
		return

	_set_stage()
	queue_redraw()


func _set_stage() -> void:
	var target_positions := [-2.2, 0.15, 2.2]
	var speeds := [2.5, 5.0, 8.0]
	var widths := [0.80, 0.48, 0.26]

	target_angle = target_positions[hits]
	needle_speed = speeds[hits]
	target_width = widths[hits]


func _draw() -> void:
	# Draw a compact panel at the upper-right of the screen.
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

	draw_rect(
		Rect2(Vector2.ZERO, panel_size),
		Color(0.02, 0.03, 0.08, 0.92)
	)
	draw_circle(centre, DIAL_RADIUS, Color(0.08, 0.12, 0.18, 1.0))
	draw_arc(centre, DIAL_RADIUS, 0.0, TAU, 80, Color(0.35, 0.45, 0.60, 1.0), 5.0)

	draw_arc(
		centre,
		DIAL_RADIUS,
		target_angle - target_width,
		target_angle + target_width,
		32,
		Color(0.20, 1.0, 0.55, 1.0),
		18.0
	)

	var needle_end := centre + Vector2(cos(needle_angle), sin(needle_angle)) * (DIAL_RADIUS - 15.0)
	draw_line(centre, needle_end, Color(1.0, 0.82, 0.22, 1.0), 6.0)
	draw_circle(centre, 12.0, Color.WHITE)

	var font := ThemeDB.fallback_font
	draw_string(font, centre + Vector2(-165, -190), "GENERATOR CALIBRATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(font, centre + Vector2(-145, 205), "Press SPACE inside the green zone", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(font, centre + Vector2(-48, 240), "Progress: %d / 3" % hits, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.20, 1.0, 0.55, 1.0))

func close() -> void:
	active = false
	visible = false
	set_process(false)
	hits = 0	
