extends CanvasLayer
 
# answer
const BUTTON_SEQUENCE: Array[String] = ["C", "B", "A"]   # blue ->yellow->red
const DIAL_TARGETS: Dictionary = {"A": 2, "B": 3, "C": 1}   # rotation_state: 0=0° 1=90° 2=180° 3=270°
 
# 玩家目前的输入记录（还没判定，纯记录）
var pressed_sequence: Array[String] = []
var dial_states: Dictionary = {"A": 0, "B": 0, "C": 0}
 
signal machine_solved
 
enum LightState { NONE, CORRECT, WRONG }
 
func _ready() -> void:
	$btnA.pressed.connect(_on_button_pressed.bind("A"))
	$btnB.pressed.connect(_on_button_pressed.bind("B"))
	$btnC.pressed.connect(_on_button_pressed.bind("C"))
 
	for dial_id in ["A", "B", "C"]:
		var dial_container = get_node("dial" + dial_id)
		var click_area = dial_container.get_node("DialClick")
		click_area.rotated.connect(_on_dial_rotated)
 
	$PowerButton.pressed.connect(_on_power_pressed)
 
	reset_machine()
 
# ---- 记录输入，不判定、不亮灯 ----
func _on_button_pressed(btn_id: String) -> void:
	if pressed_sequence.size() < BUTTON_SEQUENCE.size():
		pressed_sequence.append(btn_id)
 
func _on_dial_rotated(dial_id: String, rotation_state: int) -> void:
	dial_states[dial_id] = rotation_state
 
# ---- 按 PowerButton 才一次判定全部 6 项 ----
func _on_power_pressed() -> void:
	var all_correct := true
 
	for i in range(3):
		var correct: bool = i < pressed_sequence.size() and pressed_sequence[i] == BUTTON_SEQUENCE[i]
		_set_light_state(i + 1, LightState.CORRECT if correct else LightState.WRONG)
		if not correct:
			all_correct = false
 
	for dial_id in ["A", "B", "C"]:
		var light_index: int = {"A": 4, "B": 5, "C": 6}[dial_id]
		var correct: bool = dial_states[dial_id] == DIAL_TARGETS[dial_id]
		_set_light_state(light_index, LightState.CORRECT if correct else LightState.WRONG)
		if not correct:
			all_correct = false
 
	if all_correct:
		machine_solved.emit()
	else:
		await get_tree().create_timer(0.6).timeout
		reset_machine()
 
#  error or leave reset
func reset_machine() -> void:
	pressed_sequence.clear()
	dial_states = {"A": 0, "B": 0, "C": 0}
 
	for i in range(1, 7):
		_set_light_state(i, LightState.NONE)
 
	for dial_id in ["A", "B", "C"]:
		var dial_container = get_node("dial" + dial_id)
		dial_container.get_node("pointer").rotation_degrees = 0
		dial_container.get_node("DialClick").rotation_state = 0
 
func _set_light_state(index: int, state: LightState) -> void:
	var light: Node2D = get_node("Light" + str(index))
	light.get_node("White").visible = (state == LightState.NONE)
	light.get_node("Cyan").visible = (state == LightState.CORRECT)
	light.get_node("Red").visible = (state == LightState.WRONG)
