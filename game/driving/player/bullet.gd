extends Node3D
class_name bullet

var target
var spawn : Node3D
var offset : Vector3
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func initialize():
	if target is Vector3:
		scale.z = global_position.distance_to(target + global_position)
	else:
		scale.z = global_position.distance_to(target.global_position + offset) 
		#look_at(target.global_position + offset)
	animation_player.play("vanish")

func destroy() -> void:
	queue_free()

func _process(_delta: float) -> void:
	global_position = spawn.global_position
	if target is Vector3:
		look_at(target)
