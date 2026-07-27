extends Control

@onready var volume_label = $VolumePercentageLabel

func _ready() -> void:
	_on_master_volume_slider_value_changed($MasterVolumeSlider.value)

func _on_master_volume_slider_value_changed(value: float) -> void:
	var volume = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, volume)

	volume_label.text = str(int(value)) + "%"
	print("Master Volume: ", int(value), "%")
