extends Area3D

@export var timeline : String = "catch_up"

func _ready() -> void:
	body_entered.connect(check_for_player)

func check_for_player(body : Node3D):
	if body.is_in_group("player"):
		Utils.start_dialogue(timeline)
