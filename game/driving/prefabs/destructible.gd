extends StaticBody3D

const DAMAGED_MATERIAL = preload("res://game/driving/prefabs/destructible/damaged_material.tres")
@onready var mesh_instance_3d: MeshInstance3D = $".."
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

var hp : float = Globals.destructible_hp
var dead : bool = false

func _ready() -> void:
	collision_shape_3d.shape = mesh_instance_3d.mesh.create_trimesh_shape()

func takeDamage(amount) -> void:
	if dead:
		return
	mesh_instance_3d.material_override = DAMAGED_MATERIAL
	hp -= amount
	if hp <= 0.0:
		dead = true
		await get_tree().create_timer(0.2).timeout
		queue_free()
	await get_tree().create_timer(.2).timeout
	mesh_instance_3d.material_override = null
