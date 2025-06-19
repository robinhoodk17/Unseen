extends Area3D

@onready var light: CSGMesh3D = $LampPost/Light

func _process(delta: float) -> void:
	if !light.visible:
		return
	for i : Node3D in get_overlapping_bodies():
		if i.is_in_group("player"):
			if !i.invisible:
				Signalbus.playerspotted.emit()
