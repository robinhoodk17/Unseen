extends Node3D

const DAMAGED_MATERIAL = preload("res://game/driving/prefabs/destructible/damaged_material.tres")

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

var damage_timer: Timer
var hp: float = Globals.destructible_hp
var dead: bool = false

func _ready() -> void:
	await ensure_mesh_is_ready()
	if mesh_instance_3d.mesh != null:
		collision_shape_3d.shape = mesh_instance_3d.mesh.create_trimesh_shape()
	else:
		push_warning("Mesh is still null — cannot generate collision shape.")

	damage_timer = Utils.create_timer(0.2)
	add_child(damage_timer)
	damage_timer.timeout.connect(return_to_normal_color)

func ensure_mesh_is_ready() -> void:
	# Wait for at least 1 frame so the mesh has a chance to load
	await get_tree().process_frame
	# Optional: Wait more frames or add logic if you dynamically assign mesh later

func takeDamage(amount) -> void:
	if dead:
		return
	mesh_instance_3d.material_override = DAMAGED_MATERIAL
	hp -= amount
	if hp <= 0.0:
		dead = true
		play_death_animation()
	damage_timer.start()

func return_to_normal_color() -> void:
	mesh_instance_3d.material_override = null

func play_death_animation() -> void:
	if animation_player.has_animation("Action"):
		animation_player.play("Action")
		await animation_player.animation_finished
	get_parent().queue_free()
