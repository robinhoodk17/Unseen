extends Area3D

var timeline : String = "catch_up"

func _ready() -> void:
	body_entered.connect(check_for_player)

func check_for_player(body : Node3D):
	if body.is_in_group("player"):
		Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		Dialogic.start(timeline).process_mode = Node.PROCESS_MODE_ALWAYS
		Dialogic.timeline_ended.connect(func():get_tree().set('paused', false))
