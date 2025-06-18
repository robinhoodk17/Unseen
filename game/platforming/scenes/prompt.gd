extends Label

@export var interact_action : GUIDEAction = null

@onready var prompt: RichTextLabel = $RichTextLabel

func _ready() -> void:
	GUIDE.input_mappings_changed.connect(update)
	call_deferred("update")

func update() -> void:
	if interact_action == null:
		prompt.hide()
		return
	var formatter : GUIDEInputFormatter = GUIDEInputFormatter.for_active_contexts(20)
	var input_label  = await formatter.action_as_richtext_async(interact_action)
	prompt.text = "[center]%s[center]" % [input_label]
