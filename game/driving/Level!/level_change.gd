extends Area3D

func _ready() -> void:
	body_entered.connect(check_for_player)

func check_for_player(body : Node3D) -> void:
	if body.is_in_group("player"):
		Ui.change_scene("uid://bjk3ls1owsaib")
