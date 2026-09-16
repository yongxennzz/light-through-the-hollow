extends Node2D  # 或者你 Level3 实际继承的类型

func _on_zon_a_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Guardian.global_position = $GuardianPostA.global_position
		$Guardian.visible = true

func _on_zon_b_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Guardian.global_position = $GuardianPostB.global_position
		$Guardian.visible = true
