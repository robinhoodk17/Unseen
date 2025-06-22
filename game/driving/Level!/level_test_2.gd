extends Node3D

func _ready() -> void:
	Ui.go_to("Game")
	Utils.start_dialogue("catch_up")
