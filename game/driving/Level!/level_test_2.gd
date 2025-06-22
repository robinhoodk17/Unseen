extends Node3D

func _ready() -> void:
	Utils.start_dialogue("catch_up")
	await get_tree().create_timer(.1).timeout
	Ui.go_to("Game")
