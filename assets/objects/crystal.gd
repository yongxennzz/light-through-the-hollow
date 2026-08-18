extends Area2D


func interact(player):
	print("Crystal collected")

	get_tree().current_scene.level_complete()

	queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		body.nearby_interactables.append(self)
		print("Player near crystal")


func _on_body_exited(body):
	if body.name == "Player":
		body.nearby_interactables.erase(self)
		print("Player left crystal")
