extends PathFollow3D

@export_group("GUIDE actions")
@export var direction_input : GUIDEAction
@export var boost_input : GUIDEAction
@export var acceleration_input : GUIDEAction
@export var braking_input : GUIDEAction
@export var shoot_input : GUIDEAction
@export_group("Speed_stats")
@export var invisibility_delay : float = 0.15
@export var movement_limits : Vector2 = Vector2(5.0,5.0)
@export var speed_curve : Curve
@export var max_speed : float = 200.0
@export var boost_speed : float = 200.0
@export var boost_duration : float = 2.0
#the number of seconds it takes to go from 0 to max speed
@export var acceleration_speed : float = 5.0
#the number of seconds it takes to go from max speed to 0
@export var braking_speed : float = 1.0
@export var horizontal_speed : float = 10.0
@export var vertical_speed : float = 10.0
@export_group("Nodes")
@export var mesh_container : Node3D
@export var player : CharacterBody3D
@export var player_target : Node3D
@export var boost_timer : Timer
@export var hurt_box: Area3D
@export var camera : Camera3D

@onready var invisibility_timer: Timer = create_timer(invisibility_delay)

var invisible : bool = false
var accelerating : bool = false
var braking : bool = false
var current_speed : float = 0.0
var previous_position : Vector3
var previousBasis : Basis

func _ready() -> void:
	Signalbus.playerspotted.connect(respawn)
	boost_input.triggered.connect(start_boost)
	player.top_level = true
	#hurt_box.body_entered.connect(handle_collisions)


func _physics_process(delta: float) -> void:
	if acceleration_input.value_bool:
		current_speed += delta / acceleration_speed
		if current_speed > 1.0:
			current_speed = 1.0
	if braking_input.value_bool:
		current_speed -= delta / braking_speed
		if current_speed < 0.0:
			current_speed = 0.0
	
	if boost_timer.is_stopped():
		camera.fov = lerp(camera.fov, 90.0, delta)
		progress += max_speed * speed_curve.sample(current_speed) * delta
		show()
		if invisibility_timer.is_stopped():
			invisible = false
	else:
		handle_boost(delta)

	handle_movement(delta)
	#camera.look_at(player.global_position)
	var vector_looking_at_player_target = player_target.global_position - player.global_position
	var velocity = vector_looking_at_player_target/delta
	player.velocity = velocity
	if velocity.z != 0.0:
		player.look_at(player.global_position + velocity)
	player.move_and_slide()
	previous_position = player_target.global_position

func handle_boost(delta) -> void:
	hide()
	invisible = true
	invisibility_timer.start(invisibility_delay)
	current_speed = 1.0
	camera.fov = lerp(camera.fov, 120.0, delta)
	progress += boost_speed * delta

func handle_movement(delta) -> void:
	var direction : Vector2 = direction_input.value_axis_2d
	direction.y = -direction.y
	
	if player_target.position.x >= movement_limits.x:
		if direction.x > 0:
			direction.x = 0
	
	if player_target.position.x <= -movement_limits.x:
		if direction.x < 0:
			direction.x = 0

	if player_target.position.y >= movement_limits.y:
		if direction.y > 0:
			direction.y = 0
	
	if player_target.position.y <= -movement_limits.y:
		if direction.y < 0:
			direction.y = 0
	

	var target_rotation = global_basis.rotated(mesh_container.global_basis.z, -direction.x * PI/3.0).orthonormalized()
	target_rotation = target_rotation.rotated(mesh_container.global_basis.x, direction.y * PI/3.0).orthonormalized()
	if checkForNan():
		mesh_container.global_basis = previousBasis
	else:
		previousBasis = mesh_container.global_basis
		mesh_container.global_basis = mesh_container.global_basis.slerp(target_rotation, delta * 5.0).orthonormalized()
	
	player_target.position.x += direction.x * delta * horizontal_speed
	player_target.position.y += direction.y * delta * vertical_speed

func handle_collisions(body : Node3D) -> void:
	pass


func start_boost() -> void:
	boost_timer.start(boost_duration)

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
