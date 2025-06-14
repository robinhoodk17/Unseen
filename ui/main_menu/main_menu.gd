extends UiPage

# TODO: Add a title and/or background art to main_menu.tscn

func _ready() -> void:
	call_deferred("_connect_buttons")
	if OS.get_name() == "Web":
		%Exit.hide()


func _connect_buttons() -> void:
	if ui:
		%Play.pressed.connect(_start_game)
		%HowToPlay.pressed.connect(ui.go_to.bind("HowToPlay"))
		%Settings.pressed.connect(ui.go_to.bind("Settings"))
		%Controls.pressed.connect(ui.go_to.bind("Controls"))
		%Credits.pressed.connect(ui.go_to.bind("Credits"))
		%Exit.pressed.connect(get_tree().call_deferred.bind("quit"))


func _start_game() -> void:
	# TODO: Consider adding some kind of scene transition
	await Ui.fade_to_black(1.0)
	Ui.go_to("Game")
	get_tree().change_scene_to_file("res://game/driving/game.tscn")
	Ui.fade_to_clear(1.0)
