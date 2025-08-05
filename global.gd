extends Node

func _show_movement_guide() -> void:
	const guide_scene = preload("res://instances/UI/guide.scn")
	var guide_instance = guide_scene.instantiate()
	get_tree().current_scene.add_child(guide_instance)
	guide_instance.guide_show()
