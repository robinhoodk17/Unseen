extends PathFollow3D
class_name wagon

@onready var player: player3d_second_attempt = %Player
var previous_wagon : wagon = null
var current_speed : float
var active : bool = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	call_deferred("late_ready")
	
func late_ready() -> void:
	current_speed = player.max_speed * .9
	Signalbus.player_started_boost.connect(react_to_boost)
	active = true

func takeDamage(amount) -> void:
	animation_player.play("take_damage")

func _physics_process(delta: float) -> void:
	if !active:
		return
	progress += current_speed * delta
	current_speed = move_toward(current_speed, player.max_speed * 1.25, delta)

func react_to_boost() -> void:
	current_speed = player.boost_speed * .8
