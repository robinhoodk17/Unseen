extends UiPage

@onready var damage_boost: TextureProgressBar = $DamageBoost
@onready var health: TextureProgressBar = $Health
@onready var arrow: Sprite2D = $Speedometer/Arrow
@onready var speedometer: TextureRect = $Speedometer

var boost_shown : float = 0.0
var speedometer_size : float

func _ready() -> void:
	Signalbus.damage_upgrade.connect(got_damage)
	Signalbus.current_speed.connect(adjust_speed)
	Signalbus.player_hp_update.connect(hp_update)
	damage_boost.hide()
	speedometer_size =	speedometer.size.x

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		get_tree().paused = true
		ui.go_to("PauseMenu")

func got_damage() -> void:
	damage_boost.show()
	boost_shown = 0.0

func adjust_speed(current : float = 0.0) -> void:
	arrow.position.x = current/30 * speedometer_size

func _process(delta: float) -> void:
	if boost_shown >= Globals.damage_boost_duration * .95:
		damage_boost.hide()
	
	boost_shown += delta
	damage_boost.value = boost_shown/(Globals.damage_boost_duration * .95)

func hp_update(new_hp : float) -> void:
	health.value = new_hp/100.0
	print_debug(health.value)
