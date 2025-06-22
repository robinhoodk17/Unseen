extends Polygon2D

@onready var area_2d: Area2D = $Area2D2
@onready var collision_polygon_2d: CollisionPolygon2D = $Area2D2/CollisionPolygon2D
@export var active : bool = true

func _ready() -> void:
	collision_polygon_2d.polygon = polygon

func _process(delta: float) -> void:
	if !active:
		return
	for i : Node2D in area_2d.get_overlapping_bodies():
		if i.is_in_group("player"):
			if i.landing_timer.is_stopped() or i.current_state == PlayerController.state.CLIMBING:
				if !i.invisible:
					Signalbus.playerspotted.emit()
					$AudioStreamPlayer.play()
