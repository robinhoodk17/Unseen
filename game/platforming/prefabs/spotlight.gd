extends Polygon2D

@onready var area_2d: Area2D = $Area2D2
@onready var collision_polygon_2d: CollisionPolygon2D = $Area2D2/CollisionPolygon2D

func _ready() -> void:
	collision_polygon_2d.polygon = polygon

func _process(delta: float) -> void:
	for i : Node2D in area_2d.get_overlapping_bodies():
		print_debug(i.name)
		if i.is_in_group("player"):
			if i.is_on_floor() or i.current_state == PlayerController.state.CLIMBING:
				Signalbus.playerspotted.emit()
