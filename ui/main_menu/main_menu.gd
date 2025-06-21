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
		#%Credits.pressed.connect(ui.go_to.bind("Credits"))
		%Exit.pressed.connect(get_tree().call_deferred.bind("quit"))
		await get_tree().process_frame
		%Play.grab_focus()

func show_ui() -> void:
	show()
	%Play.grab_focus()

func _start_game() -> void:
	# TODO: Consider adding some kind of scene transition
	await Ui.fade_to_black(1.0)
	Ui.go_to("Game")
	get_tree().change_scene_to_file("uid://bggyqwvvg0xvl")
	Ui.fade_to_clear(1.0)
