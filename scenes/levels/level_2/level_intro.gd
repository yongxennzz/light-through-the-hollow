extends CanvasLayer

signal dismissed

@onready var screen: Control = $Screen
@onready var continue_button: Button = \
	$Screen/IntroPanel/ContinueButton

var opened := false
var previous_pause := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen.hide()
	continue_button.pressed.connect(_dismiss)


func show_intro() -> void:
	if opened:
		return

	opened = true
	previous_pause = get_tree().paused
	screen.show()
	get_tree().paused = true


func _dismiss() -> void:
	if not opened:
		return

	screen.hide()
	opened = false
	get_tree().paused = previous_pause
	dismissed.emit()


func _exit_tree() -> void:
	if opened:
		get_tree().paused = previous_pause
