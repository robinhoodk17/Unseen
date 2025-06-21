extends CharacterBody3D
class_name player3d_second_attempt

@export var progress : float = 0.0
@export_group("GUIDE actions")
@export var direction_input : GUIDEAction
@export var boost_input : GUIDEAction
@export var acceleration_input : GUIDEAction
@export var braking_input : GUIDEAction
@export var shoot_input : GUIDEAction
@export_subgroup("Nodes")
@export var mesh_container : Node3D
@export var camera_pivot : PathFollow3D
@export var curve_follow : Path3D
@export var bullet_scene : PackedScene = preload("uid://d34trstqhio75")
@export var superbullet : PackedScene = preload("uid://d34trstqhio75")
@export var bullet_spawns : Array[Marker3D]
@export_group("camera")
@export var camera_offset : float = 2.0
@export var camera_vertical_offset : float = 0.8
@export_group("combat and health")
##the amount of damage per shot
@export var damage : float = 1.0
##time between shots
@export var fire_rate : float = 0.25
##the multiplier whenever the damage is boosted
@export var damage_bonus : float = 2.0
@export var max_hp : float = 100.0
@export var boost_cost : float = 5.0
@export var collision_hp_loss : float = 5.0
@export_group("Speed_stats")
@export var invisibility_grace : float = 0.5
@export var drag : float = 2.5
@export var limits : Vector2 = Vector2(1.5, 1.0)
##the distance we want to keep the player from the last wagon
@export var wagon_optimal_distance : float = 10.0
@export var speed_curve : Curve
@export var max_speed : float = 10.0
@export var boost_speed : float = 30.0
@export var boost_duration : float = 2.0
#the number of seconds it takes to go from 0 to max speed
@export var acceleration_speed : float = 7.5
#the number of seconds it takes to go from max speed to 0
@export var braking_speed : float = 6.0
@export var move_speed : Vector2 = Vector2(2.5, 2.5)
@export_group("responsiveness")
@export var collision_freeze : float = 0.25
@export var responsiveness : float = 20.0

@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var mesh_animations: Node3D = $MeshContainer/MeshAnimations
@onready var invisibility_timer: Timer = create_timer(invisibility_grace)
@onready var boost_timer: Timer = create_timer(boost_duration)
@onready var damage_timer: Timer = create_timer()
@onready var collision_timer : Timer = create_timer(collision_freeze)
@onready var shot_timer: Timer = create_timer(fire_rate)
@onready var aim_assist: ShapeCast3D = $AimAssist

var current_hp = max_hp
var current_boost_speed : float = max_speed
var invisible : bool = false
var current_spawn : int = 0
var running : bool = false
var setup : bool = false
var current_speed : float = 0.0
var previousBasis : Basis
var correction_strength : float
var current_wagon : wagon = null
var current_velocity : float = 0.0
var collision_vector : Vector3 


var current_direction : Vector2

func _ready() -> void:
	Signalbus.playerspotted.connect(respawn)
	boost_input.triggered.connect(start_boost)
	if curve_follow == null:
		curve_follow = get_parent()
	await Utils.reparent_node(camera_pivot,curve_follow,true)
	camera_pivot.progress = progress
	global_position = camera_pivot.global_position - global_basis.z * camera_offset
	for i in 10:
		position_camera(.1)
		global_position = camera_pivot.global_position - camera_pivot.global_basis.z * camera_offset
	running = true

func position_camera(delta) -> void :
	var camera_point : Vector3 = curve_follow.curve.get_closest_point(global_position) + curve_follow.global_position
	var offset = curve_follow.curve.get_closest_offset(global_position)
	var target_transform : Transform3D = curve_follow.curve.sample_baked_with_rotation(offset,false,true)
	camera_pivot.global_position = camera_point
	camera_pivot.basis = target_transform.basis
	aim_assist.global_basis = camera_pivot.global_basis
	
	var relative_position : Vector3 = global_position - camera_pivot.global_position
	var distance_on_x : float = camera_pivot.global_basis.x.dot(relative_position)
	var distance_on_y : float = camera_pivot.global_basis.y.dot(relative_position)
	#
	camera_3d.position = lerp(camera_3d.position, Vector3(distance_on_x, distance_on_y + camera_vertical_offset, camera_offset), delta * 5.0)
	
	#camera_3d.look_at(global_position)
	#var target_camera_rotation : Basis = camera_3d.global_basis.looking_at(global_position)
	#camera_3d.global_basis = camera_3d.global_basis.slerp(target_camera_rotation,delta * 10.0)
	#camera_3d.rotation.x = clamp(camera_3d.rotation.x,-PI/4, PI/4)
	#camera_3d.rotation.y = clamp(camera_3d.rotation.y,-PI/4, PI/4)

func _physics_process(delta) -> void:
	if !running:
		return
	
	if !collision_timer.is_stopped():
		velocity = collision_vector
		current_direction = Vector2.ZERO
		move_and_slide()
		position_camera(delta)
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
	if boost_timer.is_stopped():
		mesh_container.show()
	else:
		z_component = -boost_speed
		current_velocity = boost_speed
		invisibility_timer.start(invisibility_grace)
		invisible = true
		mesh_container.hide()
	if invisibility_timer.is_stopped():
		invisible = false
	Signalbus.current_speed.emit(-z_component)
	var direction : Vector2 = direction_input.value_axis_2d
	if braking_input.value_bool:
		direction.y *= 3.0
	
	current_direction = lerp(current_direction, direction, delta * responsiveness)

	var x_component : float = current_direction.x * move_speed.x
	var y_component : float = -current_direction.y * move_speed.y
	mesh_container.look_at(camera_pivot.global_position - (camera_pivot.global_basis.z * 100))
	
	var relative_position : Vector3 = camera_pivot.global_position - global_position
	var relative_x : float = -camera_pivot.global_basis.x.dot(relative_position)
	var relative_y : float = global_position.y - camera_pivot.global_position.y
	
	if current_wagon != null:
		var wagon_relative_position : Vector3 = camera_pivot.global_position - current_wagon.global_position
		var wagon_relative_z : float = camera_pivot.global_basis.z.dot(wagon_relative_position)
		if wagon_relative_z < wagon_optimal_distance:
			if wagon_relative_z > 0.0:
				var correction : float = clamp((wagon_optimal_distance - wagon_relative_z), 1, 5)
				z_component /= correction

	if relative_y <= -limits.y:
		y_component -= relative_y - limits.y
	if relative_y >= limits.y:
		y_component -= relative_y + limits.y
	
	if relative_x <= -limits.x:
		x_component -= relative_x + limits.x
	if relative_x >= limits.x:
		x_component -= relative_x - limits.x
	
	var untransformed_vel : Vector3 = Vector3(x_component, y_component, z_component)
	var transformed_vel : Vector3 = camera_pivot.global_basis * untransformed_vel
	velocity = transformed_vel
	handle_animations(delta, direction)
	if shoot_input.value_bool:
		shoot(delta)
	#move_and_slide()
	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)
	
func handle_collision(collision) -> void:
	current_hp -= collision_hp_loss
	Signalbus.player_hp_update.emit(current_hp)
	collision_vector = velocity.bounce(collision.get_normal()) * 0.5
	var speed_penalty = collision_vector.dot(-global_basis.z)
	current_speed = (max_speed * speed_curve.sample(current_speed) + speed_penalty) / max_speed
	current_speed = clamp(current_speed, 0, 1.0)
	collision_timer.start(collision_freeze)

func shoot(_delta):
	if !shot_timer.is_stopped():
		return
	shot_timer.start(fire_rate)
	var actual_damage : float = damage
	#the position of the shot in the target's local space
	var offset : Vector3 = Vector3(0,0,0)
	if !damage_timer.is_stopped():
		actual_damage *= damage_bonus
	var _hitSomething : bool = false
			
	var thingWeShot : Node3D = null
	if aim_assist.is_colliding():
		thingWeShot = aim_assist.get_collider(0)
		if thingWeShot != null:
			offset = aim_assist.get_collision_point(0) - thingWeShot.global_position
			if thingWeShot.has_method("takeDamage"):
				thingWeShot.takeDamage(actual_damage)
			else:
				thingWeShot = null
	
	doShotVFX(thingWeShot, offset)
	
func doShotVFX(target, offset : Vector3):
	var newBullet : Node3D
	if damage_timer.is_stopped():
		newBullet = bullet_scene.instantiate()
	else:
		newBullet = superbullet.instantiate()
	add_child(newBullet)
	newBullet.global_position = bullet_spawns[current_spawn].global_position
	newBullet.spawn = bullet_spawns[current_spawn]
	if target == null:
		var space_state = camera_3d.get_world_3d().direct_space_state
		var origin = bullet_spawns[current_spawn].global_position
		var end = origin - bullet_spawns[current_spawn].global_basis.z * 300
		var query = PhysicsRayQueryParameters3D.create(origin,end)
		query.collide_with_bodies = true
		var result : Dictionary = space_state.intersect_ray(query)
		if !result.is_empty():
			target = result.position
		else:
			target = aim_assist.global_position + aim_assist.target_position
		newBullet.target = target
		Signalbus.shotSignal.emit()
		newBullet.look_at(target)
	else:
		newBullet.target = target
		Signalbus.shotSignal.emit()
		newBullet.look_at(target.global_position)
	newBullet.offset = offset
	newBullet.initialize()
	current_spawn = (current_spawn + 1) % bullet_spawns.size()

func start_boost() -> void:
	take_damage(boost_cost)
	boost_timer.start(boost_duration)
	Signalbus.player_started_boost.emit()

func start_free_boost() -> void:
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

func take_damage(amount : float) -> void:
	current_hp -= amount
	current_hp = min(current_hp, max_hp)
	Signalbus.player_hp_update.emit(current_hp)

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
