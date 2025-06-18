extends Label

@export var new_scene : String
@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	area_2d.body_entered.connect(check_for_player)

func check_for_player(body : Node2D) -> void:
	if body.is_in_group("player"):
		Ui.change_scene(new_scene)
