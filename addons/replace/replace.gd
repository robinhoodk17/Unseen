@tool
extends EditorPlugin

var button: Button

func _enter_tree():
	button = Button.new()
	button.text = "Reparent to Node3D (Centered)"
	button.pressed.connect(_on_button_pressed)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, button)

func _exit_tree():
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, button)
	button.queue_free()

func _on_button_pressed():
	var editor_interface = get_editor_interface()
	var selection = editor_interface.get_selection().get_selected_nodes()

	if selection.is_empty():
		print("⚠ Нет выбранных узлов.")
		return

	var root = get_tree().edited_scene_root
	if not root:
		print("⚠ Нет активной сцены.")
		return

	var node3d = Node3D.new()
	node3d.name = "NewNode3D"
	root.add_child(node3d)
	node3d.owner = root  # Делает узел сохраняемым в сцене

	# Центровка
	var center := Vector3.ZERO
	var count := 0
	for node in selection:
		if node is Node3D:
			center += node.global_transform.origin
			count += 1

	if count > 0:
		center /= count
		node3d.global_transform.origin = center

	# Переподчиняем узлы
	for node in selection:
		if node != node3d:
			node.reparent(node3d)

	print("✅ Узлы переподчинены к Node3D, выровненному по центру.")
