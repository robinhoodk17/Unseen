extends wagon

##function implemented by subclasses called when a weak spot is destroyed
func extensible_weak_spot_event(weak_spot_number) -> void:
	if weak_spot_number == 0:
		guards[0].spawn()
