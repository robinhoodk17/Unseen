extends Node2D

func _ready() -> void:
	await get_tree().create_timer(.01).timeout
	Ui.go_to("Game2D")
	Utils.start_dialogue("inside")
