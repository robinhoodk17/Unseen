extends PathFollow3D
class_name wagon

signal died

@export var wagon_number : int = 0
@export var weak_spots : Array[WeakSpot]

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: player3d_second_attempt = %Player

var vulnerable : bool = false
var previous_wagon : wagon = null
var current_speed : float
var active : bool = false
var current_hp = Globals.wagon_hp

##function implemented by subclasses
func extensible_weak_spot_event(weak_spot_number) -> void:
	pass
##function implemented by subclasses
func extensible_ready() -> void:
	pass
##function implemented by subclasses
func extensible_wagon_event() -> void:
	pass
##function implemented by subclasses
func extensible_process(delta) -> void:
	pass

func _ready() -> void:
	call_deferred("late_ready")
	
func late_ready() -> void:
	current_speed = player.max_speed * 1.1
	Signalbus.player_started_boost.connect(react_to_boost)
	active = true
	for i in weak_spots:
		i.took_damage.connect(takeDamageFromWeakSpot)
		i.died.connect(weak_spot_died)
		if i.weak_spot_number == 0 and wagon_number == 0:
			i.enable()
		else:
			i.hide()
	extensible_ready()

func weak_spot_died(weak_spot_number) -> void:
	extensible_weak_spot_event(weak_spot_number)
	if weak_spot_number < weak_spots.size() - 1:
		weak_spots[weak_spot_number + 1].enable()
		print_debug("enabled ", weak_spot_number + 1)
	else:
		vulnerable = true

func previous_wagon_died() -> void:
	extensible_wagon_event()
	weak_spots[0].enable()
	player.current_wagon = self

func takeDamage(amount) -> void:
	if !vulnerable:
		return
	animation_player.play("take_damage")
	current_hp -= amount
	if current_hp <= 0:
		if wagon_number == 2:
			Ui.change_scene("uid://bjk3ls1owsaib")
		died.emit()
		queue_free()

func takeDamageFromWeakSpot(amount) -> void:
	print_debug(wagon_number)
	animation_player.play("take_damage")

func _physics_process(delta: float) -> void:
	if !active:
		return
	progress += current_speed * delta
	current_speed = move_toward(current_speed, player.max_speed * 1.1, delta)
	extensible_process(delta)

func react_to_boost() -> void:
	current_speed = player.boost_speed * .8
