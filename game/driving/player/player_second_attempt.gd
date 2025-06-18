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
@export var drag : float = 50.0
@export var limits : Vector2 = Vector2(15, 3)
##the distance we want to keep the player from the last wagon
@export var wagon_optimal_distance : float = 100.0
@export var speed_curve : Curve
@export var max_speed : float = 100.0
@export var boost_speed : float = 300.0
@export var boost_duration : float = 2.0
#the number of seconds it takes to go from 0 to max speed
@export var acceleration_speed : float = 5.0
#the number of seconds it takes to go from max speed to 0
@export var braking_speed : float = 1.0
@export var move_speed : Vector2 = Vector2(25.0, 25.0)
@export_group("Nodes")
@export var mesh_container : Node3D
@export var camera_pivot : PathFollow3D
@export var curve_follow : Path3D

@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var mesh_animations: Node3D = $MeshContainer/MeshAnimations
@onready var boost_timer: Timer = create_timer(boost_duration)

var running : bool = false
var setup : bool = false
var current_speed : float = 0.0
var previousBasis : Basis
var correction_strength : float
var current_wagon : wagon = null
var current_velocity : float = 0.0

func _ready() -> void:
	boost_input.triggered.connect(start_boost)
	if curve_follow == null:
		curve_follow = get_parent()
	await Utils.reparent_node(camera_pivot,curve_follow,true)
	camera_pivot.progress = 0
	global_position = camera_pivot.global_position - global_basis.z * camera_offset
	for i in 10:
		position_camera(.1)
		global_position = camera_pivot.global_position - global_basis.z * camera_offset
	running = true

func position_camera(delta) -> void :
	var camera_point : Vector3 = curve_follow.curve.get_closest_point(global_position + mesh_container.global_basis.z * camera_offset)
	var offset = curve_follow.curve.get_closest_offset(global_position)
	var target_transform : Transform3D = curve_follow.curve.sample_baked_with_rotation(offset,false,true)
	#print_debug(camera_point)
	camera_pivot.position = camera_point
	camera_pivot.basis = target_transform.basis
	
	#camera_3d.look_at(global_position)
	#var target_camera_rotation : Basis = camera_3d.global_basis.looking_at(global_position)
	#camera_3d.global_basis = camera_3d.global_basis.slerp(target_camera_rotation,delta * 10.0)
	#camera_3d.rotation.x = clamp(camera_3d.rotation.x,-PI/4, PI/4)
	#camera_3d.rotation.y = clamp(camera_3d.rotation.y,-PI/4, PI/4)

func _physics_process(delta: float) -> void:
	if !running:
		return
	position_camera(delta)
	if acceleration_input.value_bool:
		current_speed += delta / acceleration_speed
		if current_speed > 1.0:
			current_speed = 1.0
	if braking_input.value_bool:
		current_speed -= delta / braking_speed
		if current_speed < 0.0:
			current_speed = 0.0
	var z_component : float = 0.0
	if current_velocity > max_speed:
		z_component = -current_velocity
		current_velocity -= drag * delta
	else:
		z_component = -max_speed * speed_curve.sample(current_speed)
	if !boost_timer.is_stopped():
		z_component = -boost_speed
		current_velocity = boost_speed
	var direction : Vector2 = direction_input.value_axis_2d
	var x_component : float = direction.x * move_speed.x
	var y_component : float = -direction.y * move_speed.y
	mesh_container.look_at(camera_pivot.global_position - (camera_pivot.global_basis.z * 100))
	
	var relative_position : Vector3 = camera_pivot.global_position - global_position
	var relative_x : float = -camera_pivot.global_basis.x.dot(relative_position)
	var relative_y : float = relative_position.y
	
	if current_wagon != null:
		var wagon_relative_position : Vector3 = camera_pivot.global_position - current_wagon.global_position
		var wagon_relative_z : float = camera_pivot.global_basis.z.dot(wagon_relative_position)
		if wagon_relative_z < wagon_optimal_distance:
			if wagon_relative_z > 0.0:
				z_component /= clamp((wagon_optimal_distance - wagon_relative_z)/10, 1, 5)
	
	print_debug(velocity)
	if relative_y <= -limits.y:
		y_component = -10 * clamp(abs(relative_y), .01, 100)
	if relative_y >= limits.y:
		y_component = 10 * clamp(abs(relative_y), .01, 100)
	
	if relative_x <= -limits.x:
		x_component = 10 * clamp(abs(relative_x), .01, 100)
	if relative_x >= limits.x:
		x_component = -10 * clamp(abs(relative_x), .01, 100)
	
	var untransformed_vel : Vector3 = Vector3(x_component, y_component, z_component)
	var transformed_vel : Vector3 = camera_pivot.global_basis * untransformed_vel
	velocity = transformed_vel
	handle_animations(delta, direction)
	move_and_slide()

func start_boost() -> void:
	boost_timer.start(boost_duration)
	Signalbus.player_started_boost.emit()

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
