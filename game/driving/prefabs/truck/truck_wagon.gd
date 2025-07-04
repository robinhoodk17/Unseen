extends PathFollow3D
class_name wagon

signal died

@export var wagon_number : int = 0
@export var weak_spots : Array[WeakSpot]
@export var guards : Array[Guard]
@export var missile_spawn_points : Array[Marker3D]
@export var missile_delay : float = 1.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: player3d_second_attempt = %Player
@onready var take_damage_audio: AudioStreamPlayer = $Take_damage
@onready var take_damage_2: AudioStreamPlayer = $Take_damage2
@onready var resist_damage_audio: AudioStreamPlayer = $ResistDamage
@onready var truckwagon: MeshInstance3D = $"game jam truck/truckwagon"

var damage_timer : Timer
var missile_scene : PackedScene = preload("res://game/driving/prefabs/missile/missile.tscn")
var vulnerable : bool = false
var previous_wagon : wagon = null
var current_speed : float
var active : bool = false
var current_hp = Globals.wagon_hp

##function implemented by subclasses called when a weak spot is destroyed
func extensible_weak_spot_event(weak_spot_number) -> void:
	pass
##function implemented by subclasses
func extensible_ready() -> void:
	pass
##function implemented by subclasses called when the previous wagon dies
func extensible_wagon_event() -> void:
	pass
##function implemented by subclasses
func extensible_process(delta) -> void:
	pass

func _ready() -> void:
	damage_timer = Utils.create_timer(.2)
	add_child(damage_timer)
	damage_timer.timeout.connect(return_to_normal_color)

	call_deferred("late_ready")
	
func late_ready() -> void:
	current_speed = player.max_speed * 1.1
	Signalbus.player_started_boost.connect(react_to_boost)
	active = true
	for i : Guard in guards:
		i.player = player
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
	$WeakSpotDestroyed.play()

func previous_wagon_died() -> void:
	$WagonDestroyed.play()
	extensible_wagon_event()
	weak_spots[0].enable()
	player.current_wagon = self

func takeDamage(amount) -> void:
	if !vulnerable:
		resist_damage_audio.play()
		return
	current_hp -= amount
	take_damage_audio.play()
	take_damage_2.play()
	truckwagon.material_override = Globals.DAMAGED_MATERIAL
	damage_timer.start()
	if current_hp <= 0:
		if wagon_number == 2:
			Utils.start_dialogue("final")
			Ui.change_scene("uid://bjk3ls1owsaib")
		died.emit()
		queue_free()

func takeDamageFromWeakSpot(amount) -> void:
	truckwagon.material_override = Globals.DAMAGED_MATERIAL
	damage_timer.start()
	take_damage_audio.play()
	take_damage_2.play()

func _physics_process(delta: float) -> void:
	if !active:
		return
	progress += current_speed * delta
	current_speed = move_toward(current_speed, player.max_speed * 1.1, delta)
	extensible_process(delta)

func react_to_boost() -> void:
	current_speed = player.boost_speed * .8

func spawn_missile() -> void:
	for i in missile_spawn_points.size():
		var newMissile : Missile = missile_scene.instantiate()
		newMissile.player = player
		add_child(newMissile)
		newMissile.global_position = missile_spawn_points[i].global_position
		newMissile.delay = missile_delay
		newMissile.shot = -missile_spawn_points[i].basis.z
		newMissile.look_at(newMissile.global_position + global_basis * -missile_spawn_points[i].basis.z)
		newMissile.initialize()

func return_to_normal_color() -> void:
	truckwagon.material_override = null
