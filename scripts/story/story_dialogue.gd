extends CanvasLayer

signal finished

@export_enum("intro", "ending") var story: String = "intro"
@export_range(10.0, 80.0) var letters_per_second := 32.0

const LINES = preload("res://scripts/story/story_lines.gd")
const ASSETS := "res://assets/images/story/"
const CHROMA = preload("res://assets/images/story/portrait_chroma.gdshader")
const NAME_FONT = preload("res://assets/fonts/story/Cinzel.ttf")
const BODY_FONT = preload("res://assets/fonts/story/IMFellEnglish.ttf")

var lines: Array[Dictionary] = []
var line_index := 0
var typing := false
var transitioning := false
var completed := false
var closing := false
var previous_pause := false
var pause_owned := false
var time_to_letter := 0.0
var elapsed := 0.0
var parsed_text := ""
var current_background := ""
var visual_tween: Tween
var screen: Control
var stage: Control
var background: TextureRect
var left_portrait: TextureRect
var right_portrait: TextureRect
var speaker_label: Label
var dialogue: RichTextLabel
var arrow: Label
var counter: Label
var skip: Label
var curtain: ColorRect
var glow: TextureRect
var finish_screen: Control
var return_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_pause = get_tree().paused
	pause_owned = true
	get_tree().paused = true
	lines = LINES.ENDING if story == "ending" else LINES.INTRO
	_build_ui()
	_layout()
	get_viewport().size_changed.connect(_layout)
	_apply_line()

func _build_ui() -> void:
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(black)
	stage = Control.new()
	stage.size = Vector2(1280, 720)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(stage)
	background = _picture(Rect2(0, 0, 1280, 720))
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.70, 0.18, 0.60))
	gradient.set_color(1, Color(1.0, 0.55, 0.10, 0.0))
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.width = 256
	glow_texture.height = 256
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 0.5)
	glow = _picture(Rect2(744, 225, 170, 140))
	glow.texture = glow_texture
	glow.hide()
	var panel := NinePatchRect.new()
	panel.texture = preload("res://assets/third_party/DarkAgesUi_v1.0/32x32-Tilesheet.png")
	panel.region_rect = Rect2(0, 0, 96, 96)
	panel.position = Vector2(14, 474)
	panel.size = Vector2(1252, 236)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		panel.set_patch_margin(side, 24)
	stage.add_child(panel)
	left_portrait = _picture(Rect2(0, 360, 240, 360), true)
	right_portrait = _picture(Rect2(1020, 330, 260, 390), true)
	speaker_label = _label(Vector2(264, 500), "", 24, NAME_FONT, Color("dcc47c"))
	dialogue = RichTextLabel.new()
	dialogue.position = Vector2(264, 542)
	dialogue.size = Vector2(732, 119)
	dialogue.bbcode_enabled = true
	dialogue.scroll_active = false
	dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue.add_theme_font_override("normal_font", BODY_FONT)
	dialogue.add_theme_font_size_override("normal_font_size", 27)
	dialogue.add_theme_color_override("default_color", Color("f4e9d2"))
	stage.add_child(dialogue)
	_label(Vector2(264, 672), "Click / Enter: reveal or continue", 15, BODY_FONT, Color("c6b992"))
	counter = _label(Vector2(880, 672), "", 15, BODY_FONT, Color("c6b992"))
	arrow = _label(Vector2(978, 666), "▼", 19, null, Color("dcc47c"))
	skip = _label(Vector2(1090, 18), "Skip story  [Esc]", 17, BODY_FONT, Color("f4e9d2"))
	finish_screen = Control.new()
	finish_screen.size = Vector2(1280, 720)
	finish_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(finish_screen)
	var finish_back := ColorRect.new()
	finish_back.color = Color(0.025, 0.035, 0.035, 0.95)
	finish_back.size = Vector2(1280, 720)
	finish_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_screen.add_child(finish_back)
	var title := _label(Vector2(100, 235), "Light Through the Hollow", 42, NAME_FONT, Color("dcc47c"), finish_screen)
	title.size.x = 1080
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := _label(Vector2(100, 322), "You found the cure. You brought hope home.\n\nJourney Complete", 28, BODY_FONT, Color("f4e9d2"), finish_screen)
	subtitle.size.x = 1080
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_button = Button.new()
	return_button.position = Vector2(475, 475)
	return_button.size = Vector2(330, 54)
	return_button.text = "Return to Main Menu"
	return_button.add_theme_font_override("font", NAME_FONT)
	return_button.add_theme_font_size_override("font_size", 19)
	return_button.pressed.connect(_return_to_menu)
	finish_screen.add_child(return_button)
	finish_screen.hide()
	curtain = ColorRect.new()
	curtain.color = Color.BLACK
	curtain.size = Vector2(1280, 720)
	curtain.modulate.a = 0.0
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(curtain)

func _picture(rect: Rect2, keyed := false) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.position = rect.position
	image.size = rect.size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if keyed:
		var material := ShaderMaterial.new()
		material.shader = CHROMA
		image.material = material
	stage.add_child(image)
	return image

func _label(at: Vector2, text: String, font_size: int, font: Font, color: Color, parent: Node = null) -> Label:
	var label := Label.new()
	label.position = at
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	if font:
		label.add_theme_font_override("font", font)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(stage if parent == null else parent).add_child(label)
	return label

func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	stage.scale = Vector2.ONE * factor
	stage.position = (viewport_size - Vector2(1280, 720) * factor) * 0.5

func _apply_line() -> void:
	var line: Dictionary = lines[line_index]
	current_background = line["background"]
	background.texture = load(ASSETS + current_background + ".png")
	left_portrait.texture = load(ASSETS + str(line["left"]) + ".png")
	right_portrait.texture = load(ASSETS + str(line["right"]) + ".png")
	var speaker: String = line["speaker"]
	speaker_label.text = speaker if not speaker.is_empty() else "A Promise to Mum"
	var left_brightness := 1.0 if speaker == "Boy" else 0.75
	var right_brightness := 1.0 if speaker != "Boy" else 0.75
	if visual_tween:
		visual_tween.kill()
	visual_tween = create_tween().set_parallel(true)
	visual_tween.tween_property(left_portrait, "modulate", Color(left_brightness, left_brightness, left_brightness), 0.16)
	visual_tween.tween_property(right_portrait, "modulate", Color(right_brightness, right_brightness, right_brightness), 0.16)
	dialogue.text = line["text"]
	parsed_text = dialogue.get_parsed_text()
	dialogue.visible_characters = 0
	typing = true
	time_to_letter = 0.0
	arrow.hide()
	counter.text = "%d / %d" % [line_index + 1, lines.size()]
	glow.visible = line.get("brew", false)

func _process(delta: float) -> void:
	elapsed += delta
	arrow.position.y = 666 + sin(elapsed * 4.0) * 3.0
	if glow.visible:
		glow.modulate.a = 0.65 + sin(elapsed * 2.5) * 0.25
	if not typing or transitioning or completed or closing:
		return
	time_to_letter -= delta
	while time_to_letter <= 0.0 and typing:
		dialogue.visible_characters += 1
		var count := dialogue.visible_characters
		if count >= parsed_text.length():
			_reveal_all()
			break
		var character := parsed_text.substr(count - 1, 1)
		time_to_letter += 1.0 / letters_per_second
		if character in [".", "!", "?", "…"]:
			time_to_letter += 0.30
		elif character in [",", "—", ":"]:
			time_to_letter += 0.15

func _reveal_all() -> void:
	dialogue.visible_characters = -1
	typing = false
	arrow.show()

func advance() -> void:
	if transitioning or completed or closing:
		return
	if typing:
		_reveal_all()
		return
	line_index += 1
	if line_index >= lines.size():
		_finish_story()
		return
	var line: Dictionary = lines[line_index]
	if line["background"] != current_background or line.get("transition", false):
		transitioning = true
		var tween := create_tween()
		tween.tween_property(curtain, "modulate:a", 1.0, 0.24)
		tween.tween_callback(_apply_line)
		tween.tween_property(curtain, "modulate:a", 0.0, 0.24)
		tween.tween_callback(func(): transitioning = false)
	else:
		_apply_line()

func _input(event: InputEvent) -> void:
	if closing:
		return
	if completed:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_return_to_menu()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE and not transitioning:
			_finish_story()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			advance()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if skip.get_global_rect().has_point(event.position) and not transitioning:
				_finish_story()
			else:
				advance()

func _finish_story() -> void:
	if completed or closing:
		return
	typing = false
	if story == "ending":
		completed = true
		finish_screen.show()
		return_button.grab_focus()
		finished.emit()
	else:
		closing = true
		StoryState.intro_seen = true
		_release_pause()
		finished.emit()
		if get_tree().current_scene == self:
			get_tree().change_scene_to_file("res://scenes/levels/level_1/level_1.tscn")
		else:
			queue_free()

func _return_to_menu() -> void:
	if closing:
		return
	closing = true
	_release_pause()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _release_pause() -> void:
	if pause_owned:
		get_tree().paused = previous_pause
		pause_owned = false

func _exit_tree() -> void:
	_release_pause()
