extends Node3D
class_name truck

@export var wagon_size : float = 10.0
@export var space_between_wagons : float = 1.0

@onready var player : Node3D = %Player

func _ready() -> void:
	call_deferred("late_ready")
func late_ready() -> void:
	var wagon_number = get_children().size()
	var curve_follow = get_parent()
	var previous_wagon = null
	for i in get_children():
		i.previous_wagon = previous_wagon
		previous_wagon = i
	player.current_wagon = previous_wagon
	for i in get_children():
		i.reparent(curve_follow, false)
		i.player = player
		i.progress = (wagon_number * wagon_size/2) + space_between_wagons + wagon_size + player.progress
		wagon_number -= 1
