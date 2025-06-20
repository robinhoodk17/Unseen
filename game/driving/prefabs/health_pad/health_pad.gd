extends Area3D

@export var health_recovered : float = 20.0

@onready var start_moving: Area3D = $StartMoving
var moving : bool = false
@onready var parent_follower: PathFollow3D = $".."

func _ready() -> void:
	body_entered.connect(check_for_player)
	start_moving.body_entered.connect(check_to_move)

func check_for_player(body : Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(-health_recovered)
		queue_free()

func check_to_move(body : Node3D) -> void:
	if body.is_in_group("player"):
		moving = true

func _physics_process(delta: float) -> void:
	if moving:
		parent_follower.progress += Globals.collectibles_speed * delta
