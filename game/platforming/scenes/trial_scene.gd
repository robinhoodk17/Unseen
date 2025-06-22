extends Node2D

func _ready() -> void:
	await get_tree().create_timer(.01).timeout
	if !Ui.is_shown("Game2D"):
		Ui.go_to("Game2D")
