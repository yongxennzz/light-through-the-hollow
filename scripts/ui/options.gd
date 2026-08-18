extends Control

@onready var volume_label = $VolumePercentageLabel

func _ready() -> void:
	$MasterVolumeSlider.value = Settings.music_volume
	_on_master_volume_slider_value_changed(Settings.music_volume)


func _on_master_volume_slider_value_changed(value: float) -> void:
	Settings.music_volume = value

	var volume = linear_to_db(value / 100.0) #godot use decibels not percentage
	AudioServer.set_bus_volume_db(0, volume)

	volume_label.text = str(int(value)) + "%" #volume percentage label
