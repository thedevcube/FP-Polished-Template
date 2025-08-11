extends Node

func _show_movement_guide() -> void:
	const guide_scene = preload("res://instances/UI/guide.scn")
	var guide_instance = guide_scene.instantiate()
	get_tree().current_scene.add_child(guide_instance)
	guide_instance.guide_show()

func _move_3d_editor_camera_to(to: Vector3) -> void:
	EditorInterface.get_editor_viewport_3d(0).get_camera_3d().position = to
