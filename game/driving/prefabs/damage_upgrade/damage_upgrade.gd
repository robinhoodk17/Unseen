extends Area3D

@onready var start_moving: Area3D = $StartMoving
var moving : bool = false
@onready var damage_upgrade: PathFollow3D = $".."

func _ready() -> void:
	body_entered.connect(check_for_player)
	start_moving.body_entered.connect(check_to_move)

func check_for_player(body : Node3D) -> void:
	if body.is_in_group("player"):
		body.damage_timer.start(Globals.damage_boost_duration)
		Signalbus.damage_upgrade.emit()
		queue_free()

func check_to_move(body : Node3D) -> void:
	if body.is_in_group("player"):
		moving = true

func _physics_process(delta: float) -> void:
	if moving:
		damage_upgrade.progress += Globals.collectibles_speed * delta
