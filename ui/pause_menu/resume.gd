extends Button

@onready var node: AnimationComponent = $Node

func _ready() -> void:
	node.finished_entering.connect(grab)

func grab(finished : bool) -> void:
	await get_tree().process_frame
	grab_focus()
