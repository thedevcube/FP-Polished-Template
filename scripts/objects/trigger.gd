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
	## When entering this trigger's area (not WHILE inside it.)
	enter ,
	## When leaving this trigger's area
	exit ,
}

var last_entered_body: Node3D
## What commands to include when triggering this trigger
@export_flags("Enable teleport" , "Enable show text") var enabled_commands = 0: 
	set(value):
		enabled_commands = value
		if enabled_commands & 1:
			$EditorRelated/TeleportTarget.show(); $EditorRelated/TeleportTarget.global_position = teleport_position
		else: $EditorRelated/TeleportTarget.hide()
## Mode of triggering
@export var trigger_mode: triggermode





@export_group("Properties")

#region Teleporting properties
@export_subgroup("Teleporting")
## Nodes that shouldn't be teleported.
@export var filtered_nodes: Array[Node3D] = []
## If the trigger should completely stop the body's velocity when teleporting - If one.
@export var teleport_reset_velocity := false

## Remove any pending animation from the body - for example the player, its pending animations are impact animations.
@export var teleport_reset_pending_animations := true
## Delay before teleporting an node.
@export var teleport_delay: float = 0.0

@export var teleport_position: Vector3 = Vector3.ZERO:
		set(value):
			if not Engine.is_editor_hint(): return ## If not in editor, return
			teleport_position = value
			if not $EditorRelated/TeleportTarget.visible: $EditorRelated/TeleportTarget.show()
			$EditorRelated/TeleportTarget.global_position = value

@export_tool_button("Move camera to teleport position" , "Translation") var snap_cam_to: Callable = func():
	if not Engine.is_editor_hint(): return ## If not in editor, return
	global._move_3d_editor_camera_to(teleport_position)

@export_tool_button("Set as camera position") var set_campos: Callable = func():
	if not Engine.is_editor_hint(): return ## If not in editor, return
	teleport_position = EditorInterface.get_editor_viewport_3d(0).get_camera_3d().global_position
#endregion

#region Display text properties
@export_subgroup("Displayed text")
@export_multiline var text_displayed: String = ""
@export var text_color: Color = Color.WHITE
## Time in seconds before the text is displayed
@export var text_delay: float = 0.0
@export var text_fade_in_seconds: float = 0.5
## After fade in, for how many seconds to stay before fading out
@export var text_hold_seconds: float = 1.0
@export var text_fade_out_seconds: float = 0.5
var previewing_text = false
@export_tool_button("Preview") var text_preview: Callable = func():
	if not Engine.is_editor_hint(): return ## If not in editor, return
	if not previewing_text:
		if not (enabled_commands & 2): push_error("Trigger type is not an show text type."); return
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
	if not enabled_commands: assert(false , str("You did not set any enabled commands - " , self , " - at (pos): - " , global_position))
	if trigger_mode == triggermode.exit: return
	if body in filtered_nodes: return

	last_entered_body = body

	trigger(body)



func body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint(): return ## Don't trigger inside the editor
	if not enabled_commands: assert(false , "You did not set any enabled commands")
	if trigger_mode != triggermode.exit: return
	if body in filtered_nodes: return


	last_entered_body = body

	trigger(body)


func trigger(body: Node3D = null) -> void:
	if body and (enabled_commands & 1): # Teleport
		var in_thread = func():
			await get_tree().create_timer(teleport_delay).timeout
			if teleport_reset_pending_animations and "pending_reset" in body: body.pending_reset()
			elif teleport_reset_pending_animations: push_warning(str("Body " + str(body) + " does not have an reset_pending function."))
			if teleport_reset_velocity and "linear_velocity" in body: body.linear_velocity = Vector3.ZERO
			elif teleport_reset_velocity: push_warning(str("Body " + str(body) + " does not have an linear_velocity variable."))
			body.global_position = teleport_position
		in_thread.call()

	if body and (enabled_commands & 2): # Display text
		var text_node = $CanvasLayer/AspectRatioContainer/Label
		text_node.text = text_displayed
		await get_tree().create_timer(text_delay).timeout
		var text_tween_in = create_tween()
		text_tween_in.tween_property(text_node , "modulate" , text_color , text_fade_in_seconds)
		await text_tween_in.finished
		await get_tree().create_timer(text_hold_seconds).timeout
		var text_tween_out = create_tween()
		text_tween_out.tween_property(text_node , "modulate" , Color(text_color , 0) , text_fade_out_seconds)
