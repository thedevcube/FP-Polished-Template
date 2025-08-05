@tool
extends Area3D

## Those get deleted ingame
@export var debug_nodes: Array[Node3D]
@export_category("Trigger")

enum triggertype{
	teleport ,
	show_text
}

enum triggermode{
	enter ,
	exit ,
}

var last_entered_body: Node3D

@export var trigger_type: triggertype:
	set(value):
		trigger_type = value

		if trigger_type == triggertype.teleport:
			$EditorRelated/TeleportTarget.show(); $EditorRelated/TeleportTarget.global_position = tp_position
		else: $EditorRelated/TeleportTarget.hide()

@export var trigger_mode: triggermode





@export_group("Properties")

#region Teleporting properties
@export_subgroup("Teleporting")
@export var filtered_nodes: Array[Node3D] = []
@export var teleport_delay: float = 0.0

@export var tp_position: Vector3 = Vector3.ZERO:
		set(value):
			if not Engine.is_editor_hint(): return ## If not in editor, return
			tp_position = value
			$EditorRelated/TeleportTarget.global_position = value

@export_tool_button("Move camera to teleport position" , "Translation") var snap_cam_to: Callable = func():
	if not Engine.is_editor_hint(): return ## If not in editor, return
	EditorInterface.get_editor_viewport_3d(0).get_camera_3d().position = tp_position

@export_tool_button("Set as camera position") var set_campos: Callable = func():
	if not Engine.is_editor_hint(): return ## If not in editor, return
	tp_position = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position
#endregion

#region Display text properties
@export_subgroup("Displayed text")
@export_multiline var text_displayed: String = ""
@export var text_hold_seconds: float = 1.0
@export var text_fade_in_seconds: float = 0.5
@export var text_fade_out_seconds: float = 0.5
@export var text_delay: float = 0.0
@export var text_color: Color = Color.WHITE
var previewing_text = false
@export_tool_button("Preview") var text_preview: Callable = func():
	if not Engine.is_editor_hint(): return ## If not in editor, return
	if not previewing_text:
		if trigger_type != triggertype.show_text: push_error("Trigger type is not an show text type."); return
		previewing_text = true
		var text_node = $CanvasLayer/AspectRatioContainer/Label
		text_node.text = text_displayed
		await get_tree().create_timer(text_delay).timeout
		var text_tween_in = create_tween()
		text_tween_in.tween_property(text_node , "modulate" , text_color , text_fade_in_seconds)
		await text_tween_in.finished
		await get_tree().create_timer(text_hold_seconds).timeout
		var text_tween_out = create_tween()
		text_tween_out.tween_property(text_node , "modulate" , Color(text_color , 0) , text_fade_in_seconds)
		await text_tween_out.finished
		text_node.modulate = Color.TRANSPARENT
		previewing_text = false
	else: push_warning("Tried running preview but there's already one ongoing.")
#endregion



func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		for node in debug_nodes:
			node.queue_free()


func body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint(): return ## Don't trigger inside the editor
	if trigger_mode == triggermode.exit: return
	if body in filtered_nodes: return

	last_entered_body = body

	trigger(body)



func body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint(): return ## Don't trigger inside the editor

	if trigger_mode != triggermode.exit: return
	if body in filtered_nodes: return

	last_entered_body = body

	trigger(body)


func trigger(body: Node3D = null) -> void:
	if body and trigger_type == triggertype.teleport:
		await get_tree().create_timer(teleport_delay).timeout
		body.global_position = tp_position

	if body and trigger_type == triggertype.show_text:
		var text_node = $CanvasLayer/AspectRatioContainer/Label
		text_node.text = text_displayed
		await get_tree().create_timer(text_delay).timeout
		var text_tween_in = create_tween()
		text_tween_in.tween_property(text_node , "modulate" , text_color , text_fade_in_seconds)
		await text_tween_in.finished
		await get_tree().create_timer(text_hold_seconds).timeout
		var text_tween_out = create_tween()
		text_tween_out.tween_property(text_node , "modulate" , Color(text_color , 0) , text_fade_out_seconds)
