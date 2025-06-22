extends CharacterBody3D
class_name Missile

@export var acceleration : float = 1.25
@export_range (3, 10, 0.2) var turn_speed : float = 25.0
@export var maxSpeed : float = 100.0
@export var damage : float = 20
@export var maxHealth : float = 1.0
@export var delay : float = 0.0
@export var shot : Vector3
@export var mesh_instance_3d : MeshInstance3D

var player : player3d_second_attempt
var current_delay : float = 0.0
var current_hp : float = maxHealth
var speed = 0
var started : bool = false
var damage_timer : Timer
var previousBasis : Basis = Basis.IDENTITY

func _ready():
	damage_timer = Utils.create_timer(.2)
	add_child(damage_timer)
	damage_timer.timeout.connect(return_to_normal_color)
	
func initialize():
	visible = true
	
func takeDamage(amount):
	current_hp -= amount
	mesh_instance_3d.material_override = Globals.DAMAGED_MATERIAL
	damage_timer.start()
	if current_hp <= 0:
		queue_free()
	
	
func rotateObject(delta):
	var heading : Vector3
	heading = player.global_position
	var look_atMatrix : Basis = global_basis.looking_at(heading - global_position).orthonormalized()
	
	if checkForNan():
		global_basis = previousBasis
	else:
		previousBasis = global_basis
		global_basis = global_basis.slerp(look_atMatrix, delta * 5.0).orthonormalized()

	global_basis = global_basis.slerp(look_atMatrix,delta * turn_speed).orthonormalized()
	#global_transform.basis.y=lerp(global_transform.basis.y, look_atMatrix.basis.y, delta*turn_speed)
	#global_transform.basis.x=lerp(global_transform.basis.x, look_atMatrix.basis.x, delta*turn_speed)
	#global_transform.basis.z=lerp(global_transform.basis.z, look_atMatrix.basis.z, delta*turn_speed)
	#transform.basis = transform.basis.orthonormalized()

func _physics_process(delta):
	if current_delay < delay:
		current_delay += delta
		velocity = shot.normalized()
		move_and_slide()
		return

	velocity = -global_basis.z * speed
	if speed < maxSpeed:
		speed += acceleration * delta
	rotateObject(delta)
	#print_debug(velocity)
	var collision = move_and_collide(velocity*delta)
	if collision != null:
		if collision.get_collider() != null:
			if collision.get_collider().has_method("take_damage"):
				collision.get_collider().take_damage(damage)
			queue_free()

func return_to_normal_color() -> void:
	mesh_instance_3d.material_override = null

func checkForNan() -> bool:
	var checkingBasis : Basis = global_basis
	if is_nan(checkingBasis.x.x) or is_nan(checkingBasis.x.y) or is_nan(checkingBasis.x.z):
		return true
	if is_nan(checkingBasis.y.x) or is_nan(checkingBasis.y.y) or is_nan(checkingBasis.y.z):
		return true
	if is_nan(checkingBasis.z.x) or is_nan(checkingBasis.z.y) or is_nan(checkingBasis.z.z):
		return true
	return false
