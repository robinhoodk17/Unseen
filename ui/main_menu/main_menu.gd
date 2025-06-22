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
	Ui.go_to("Game2D")
	Ui.change_scene("uid://bjk3ls1owsaib")
