extends UiPage

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		get_tree().paused = true
		ui.go_to("PauseMenu")

func show_ui() -> void:
	if !audio_stream_player.playing:
		audio_stream_player.play()
