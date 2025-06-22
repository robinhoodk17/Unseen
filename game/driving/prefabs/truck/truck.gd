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
	for i in get_children().size():
		var current_wagon : wagon = get_child(get_children().size() - i -1)
		current_wagon.previous_wagon = previous_wagon
		if previous_wagon != null:
			previous_wagon.died.connect(current_wagon.previous_wagon_died)
		else:
			player.current_wagon = current_wagon
		previous_wagon = current_wagon
	for i in get_children():
		i.reparent(curve_follow, false)
		i.player = player
		i.progress = (wagon_number * wagon_size) + space_between_wagons + wagon_size + player.progress
		wagon_number -= 1
