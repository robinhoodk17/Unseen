extends PathFollow3D

@onready var player: player3d_second_attempt = %Player
var current_speed : float

func _ready() -> void:
	current_speed = player.max_speed * 1.25
	Signalbus.player_started_boost.connect(react_to_boost)

func _physics_process(delta: float) -> void:
	progress += current_speed * delta
	current_speed = move_toward(current_speed, player.max_speed * 1.25, delta)

func react_to_boost() -> void:
	current_speed = player.boost_speed * .8
