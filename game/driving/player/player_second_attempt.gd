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
@export var limits : Vector2 = Vector2(25, 10)
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
@onready var mesh_animations: Node3D = $MeshContainer/MeshAnimations

@export var curve_follow : Path3D

var running : bool = false
var current_speed : float = 0.0
var previousBasis : Basis

func _ready() -> void:
	if curve_follow == null:
		curve_follow = get_parent()
	await Utils.reparent_node(camera_pivot,curve_follow,true)
	camera_pivot.progress = 0
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
	var relative_position : Vector3 = camera_pivot.global_position - global_position	
	var relative_x : float = camera_pivot.global_basis.x.dot(relative_position)
	var relative_y : float = relative_position.y
	
	#var wagon_relative_position : Vector3 = camera_pivot.global_position - current_wagon.global_position
	#var wagon_relative_z : float = -camera_pivot.global_basis.z.dot(wagon_relative_position)
	
	if relative_y < -limits.y:
		y_component = 10
	if relative_y > limits.y:
		y_component = -10
	
	if relative_x < -limits.x:
		x_component = 10
	if relative_x > limits.x:
		x_component = -10
	
	#if wagon_relative_z < wagon_optimal_distance:
		#pass
	handle_animations(delta, direction)
	move_and_slide()

func handle_animations(delta : float, direction : Vector2) -> void:
	var target_rotation = mesh_container.global_basis.rotated(mesh_container.global_basis.z, -direction.x * PI/3.0).orthonormalized()
	target_rotation = target_rotation.rotated(mesh_container.global_basis.x, direction.y * PI/3.0).orthonormalized()
	if checkForNan():
		mesh_animations.global_basis = previousBasis
	else:
		previousBasis = mesh_animations.global_basis
		mesh_animations.global_basis = mesh_animations.global_basis.slerp(target_rotation, delta * 5.0).orthonormalized()

#region utilities
func create_timer(wait_time: float = 1.0, one_shot: bool = true) -> Timer:
	var timer : Timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = one_shot
	add_child(timer)
	return timer

func checkForNan() -> bool:
	var checkingBasis : Basis = mesh_container.global_basis
	if is_nan(checkingBasis.x.x) or is_nan(checkingBasis.x.y) or is_nan(checkingBasis.x.z):
		return true
	if is_nan(checkingBasis.y.x) or is_nan(checkingBasis.y.y) or is_nan(checkingBasis.y.z):
		return true
	if is_nan(checkingBasis.z.x) or is_nan(checkingBasis.z.y) or is_nan(checkingBasis.z.z):
		return true
	return false

func respawn() -> void:
	get_tree().paused = true
	await get_tree().create_timer(0.75).timeout
	get_tree().paused = false
	await Ui.fade_to_black(0.01)
	get_tree().reload_current_scene()
	await Ui.fade_to_clear(0.01)
#endregion
