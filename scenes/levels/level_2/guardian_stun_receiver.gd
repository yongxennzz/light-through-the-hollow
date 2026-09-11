extends Area2D
# Adapter for the shared player torch's Area2D interface.

func stun() -> void:
	get_parent().stun()
