extends CharacterBody3D
class_name player3d_second_attempt

@export_group("GUIDE actions")
@export var direction_input : GUIDEAction
@export var boost_input : GUIDEAction
@export var acceleration_input : GUIDEAction
@export var braking_input : GUIDEAction
@export var shoot_input : GUIDEAction
@export_group("camera")
@export var camera_offset : float = 10.0
@export_group("Speed_stats")
@export var speed_curve : Curve
@export var max_speed : float = 100.0
#the number of seconds it takes to go from 0 to max speed
@export var acceleration_speed : float = 5.0
#the number of seconds it takes to go from max speed to 0
@export var braking_speed : float = 1.0
@export var move_speed : Vector2 = Vector2(25.0, 25.0)
@export_group("Nodes")
@export var mesh_container : Node3D
@export var camera_pivot : PathFollow3D
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D

@export var curve_follow : Path3D

var running : bool = false
var current_speed : float = 0.0

func _ready() -> void:
	await Utils.reparent_node(camera_pivot,curve_follow,true)
	global_position = camera_pivot.global_position - global_basis.z * camera_offset
	running = true

func _physics_process(delta: float) -> void:
	if !running:
		return
	var camera_point : Vector3 = curve_follow.curve.get_closest_point(global_position + mesh_container.global_basis.z * camera_offset)
	var offset = curve_follow.curve.get_closest_offset(global_position)
	var target_transform : Transform3D = curve_follow.curve.sample_baked_with_rotation(offset,false,true)
	camera_pivot.global_position = camera_point
	camera_pivot.global_basis = target_transform.basis
	print_debug(camera_pivot.global_basis)
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
	var x_component : float = direction.x * move_speed.x
	var y_component : float = -direction.y * move_speed.y
	mesh_container.look_at(camera_pivot.global_position - (camera_pivot.global_basis.z * 100))
	var untransformed_vel : Vector3 = Vector3(x_component, y_component, z_component)
	var transformed_vel : Vector3 = camera_pivot.global_basis * untransformed_vel
	#if global_position * global_basis.x 
	camera_3d.look_at(global_position)
	velocity = transformed_vel
	
	move_and_slide()
