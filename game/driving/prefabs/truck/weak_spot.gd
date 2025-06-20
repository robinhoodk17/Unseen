extends StaticBody3D
class_name WeakSpot

signal took_damage(amount)
signal died(number)
const DAMAGED_MATERIAL = preload("res://game/driving/prefabs/destructible/damaged_material.tres")
@export var mesh_instance_3d: MeshInstance3D
@export var weak_spot_number : int = 0
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var active : bool = false
var hp : float = Globals.weak_point_hp
var dead : bool = false

func enable() -> void:
	active = true
	collision_layer = 1
	show()

func _ready() -> void:
	collision_shape_3d.shape = mesh_instance_3d.mesh.create_trimesh_shape()
	hide()

func takeDamage(amount) -> void:
	if dead:
		return
	mesh_instance_3d.material_override = DAMAGED_MATERIAL
	hp -= amount
	took_damage.emit(amount)
	if hp <= 0.0:
		dead = true
		died.emit(weak_spot_number)
		await get_tree().create_timer(0.2).timeout
		queue_free()
	await get_tree().create_timer(.2).timeout
	mesh_instance_3d.material_override = null
