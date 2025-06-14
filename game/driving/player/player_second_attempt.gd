extends CharacterBody3D

@export_group("GUIDE actions")
@export var direction_input : GUIDEAction
@export var boost_input : GUIDEAction
@export var acceleration_input : GUIDEAction
@export var braking_input : GUIDEAction
@export var shoot_input : GUIDEAction
@export_group("camera")
@export var offset : Vector3 = Vector3(0, 0, 10)
@export_group("Speed_stats")
@export var speed_curve : Curve
@export var max_speed : float = 200.0
#the number of seconds it takes to go from 0 to max speed
@export var acceleration_speed : float = 5.0
#the number of seconds it takes to go from max speed to 0
@export var braking_speed : float = 1.0
@export var horizontal_speed : float = 50.0
@export var vertical_speed : float = 50.0
@export_group("Nodes")
@export var mesh_container : Node3D
@export var camera_pivot : PathFollow3D
@export var curve_follow : Path3D

var current_speed : float = 0.0

#func _ready() -> void:
	#Utils.reparent_node(camera_pivot,curve_follow,true)

func _physics_process(delta: float) -> void:
	var camera_point : Vector3 = curve_follow.curve.get_closest_point(global_position + offset)
	camera_pivot.global_position = camera_point
	if acceleration_input.value_bool:
		current_speed += delta / acceleration_speed
		if current_speed > 1.0:
			current_speed = 1.0
	if braking_input.value_bool:
		current_speed -= delta / braking_speed
		if current_speed < 0.0:
			current_speed = 0.0

	var z_component : float= -max_speed * speed_curve.sample(current_speed)
	
	var direction : Vector2 = direction_input.value_axis_2d
	#if global_position * global_basis.x 
	
	move_and_slide()
