extends wagon

##function implemented by subclasses called when the previous wagon dies
func extensible_wagon_event() -> void:
	guards[0].spawn()
	guards[1].spawn()

func extensible_weak_spot_event(weak_spot_number) -> void:
	guards[0].spawn()
	guards[1].spawn()
	guards[2].spawn()
