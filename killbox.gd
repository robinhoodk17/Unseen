extends Area2D

func _ready() -> void:
	body_entered.connect(respawn)

func respawn(body : Node2D) -> void:
		if body.is_in_group("player"):
			body.respawn()
