extends wagon

var spawn_missile_timer : Timer
##function implemented by subclasses
func extensible_ready() -> void:
	spawn_missile_timer = Utils.create_timer(5.0, false)
	add_child(spawn_missile_timer)
	spawn_missile_timer.timeout.connect(spawn_missile)

##function implemented by subclasses called when the previous wagon dies
func extensible_wagon_event() -> void:
	guards[0].spawn()
	guards[1].spawn()

func extensible_weak_spot_event(weak_spot_number) -> void:
	guards[0].spawn()
	guards[1].spawn()
	guards[2].spawn()
	spawn_missile()
	spawn_missile_timer.start()
