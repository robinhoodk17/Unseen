extends StaticBody3D
class_name Guard

@export var mesh_instance_3d: MeshInstance3D
@export var missile_scene : PackedScene = preload("res://game/driving/prefabs/missile/missile.tscn")
@export var max_hp : float = 10.0
@export var missile_spawn_location : Marker3D
@export var shot_direction : Vector3 = Vector3(0,1,-1)

var player : player3d_second_attempt
var current_hp = max_hp
var dead : bool = true
var damage_timer : Timer
var spawn_missile_timer : Timer
var respawn_timer : Timer

func _ready() -> void:
	damage_timer = Utils.create_timer(.2)
	add_child(damage_timer)
	damage_timer.timeout.connect(return_to_normal_color)
	
	spawn_missile_timer = Utils.create_timer(7.5, false)
	add_child(spawn_missile_timer)
	spawn_missile_timer.timeout.connect(spawn_missile)
	
	respawn_timer = Utils.create_timer(15.0)
	add_child(respawn_timer)
	respawn_timer.timeout.connect(spawn)
	hide()
	collision_layer = 0

func spawn() -> void:
	show()
	dead = false
	spawn_missile_timer.start()
	collision_layer = 1
	current_hp = max_hp

func spawn_missile() -> void:
	if dead:
		return
	var newMissile : Missile = missile_scene.instantiate()
	newMissile.player = player
	newMissile.shot = shot_direction
	newMissile.delay = 1.0
	add_child(newMissile)
	newMissile.add_collision_exception_with(self)
	newMissile.global_position = missile_spawn_location.global_position
	newMissile.look_at(newMissile.global_position + shot_direction)
	newMissile.initialize()

func die() -> void:
	dead = true
	hide()
	collision_layer = 0
	respawn_timer.start()

func takeDamage(amount) -> void:
	if dead:
		return
	mesh_instance_3d.material_override = Globals.DAMAGED_MATERIAL
	damage_timer.start()
	current_hp -= amount
	if current_hp <= 0:
		die()

func return_to_normal_color() -> void:
	mesh_instance_3d.material_override = null
	
