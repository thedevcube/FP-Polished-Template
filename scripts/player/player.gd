extends RigidBody3D

## Player camera
@export var camera: Camera3D
@export var mouse_sensitivity := 0.002
## Pivot is like a neck, for the camera
@export var pivot: Marker3D
## Player colision
@export var col: CollisionShape3D
## Used by the on_floor() function.
@export var floor_cast: ShapeCast3D
## Get up raycast object, Checks if there's no object above player before standing up from crouching.
@export var getup_cast: RayCast3D

@export var audio_player: AudioStreamPlayer3D
@export var player_tree: AnimationTree

## speed to apply to the WASD movement, its interpolated up when clicking wasd.
var speed = 0.0
var max_speed = 5.0
## For how much seconds the linear velocity is less than 0, or casually speaking, falling.
var airtime := 0.0
var crouched := false
var sprinting := false
## If disabled, disables rotating camera and WASD movement.
var control_enabled := true
## If the player should do the fall animation when landing on the ground
var do_fall_animation := false
var do_lightfall_animation := false
var mouse_speed := Vector2.ZERO

func _input(event: InputEvent) -> void:
# Set the mouse speed when the mouse is moving
	if event is InputEventMouseMotion:
		mouse_speed = event.relative

	if Input.is_key_pressed(KEY_Z):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
## Detects if player fell and if there's any pending animations, then trigger the pending animation if so.
	if on_floor() and (do_fall_animation or do_lightfall_animation):
		if do_fall_animation: control_enabled = false

		var playback = player_tree.get("parameters/playback")
		if do_fall_animation: playback.travel("impact")
		if do_lightfall_animation: playback.travel("impact_light")
		crouch(false)
		set_deferred("max_speed" , 5)
		audio_player.play()

		if do_fall_animation: var tween = create_tween(); tween.tween_property(pivot , "rotation:x" , 0 , 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		do_fall_animation = false
		do_lightfall_animation = false

		await player_tree.animation_finished
		audio_player.stop()
		control_enabled = true
## Rotate the player camera around
	if (mouse_speed.length() > 0.01) and control_enabled: 
		pivot.rotation.y = (pivot.rotation.y + -mouse_speed.x * mouse_sensitivity)
		pivot.rotation.x = (clamp(pivot.rotation.x - mouse_speed.y * mouse_sensitivity, deg_to_rad(-89), deg_to_rad(89)))
		mouse_speed = mouse_speed.cubic_interpolate(Vector2.ZERO , mouse_speed , Vector2.ZERO , 0.2)

func _physics_process(delta: float) -> void:
# If the player is not on ground, update airtime. Then modify the v_offset of the camera to make the landing effect
	if linear_velocity.y < 0 and not on_floor(): 
		airtime += delta
		var tween = create_tween()
		tween.tween_property(camera , "v_offset" , clamp(linear_velocity.y , -1 , 0) , 0.25).set_ease(Tween.EASE_IN_OUT)
	else: airtime = 0 # Reset if not.

# Reset camera v_offset
	if camera.v_offset != 0.0: var tween = create_tween(); tween.tween_property(camera , "v_offset" , 0.0 , 1).set_ease(Tween.EASE_IN_OUT)

# Self explanative i think, if falling too fast enable falling animations.
	if linear_velocity.y < -15: do_fall_animation = true; do_lightfall_animation = false
	if linear_velocity.y < -11 and not do_fall_animation: do_lightfall_animation = true

# Idk what this is really it just looks kinda cool, makes the camera start spinning on rotation x axis after falling for a while.
# (camera x rotation axis gets corrected after doing an fall animation including light fall.)
	if linear_velocity.y != 0.0 and not on_floor():
		pivot.rotation.x += clamp((deg_to_rad(linear_velocity.y / 50) * airtime), deg_to_rad(-25), deg_to_rad(25))


	var direction = Vector3.ZERO

	var _basis_f = pivot.transform.basis.z
	_basis_f.y = 0
	_basis_f = _basis_f.normalized()

	if Input.is_action_pressed("Forward") and on_floor() and control_enabled:
		direction -= _basis_f; speed = clamp(speed + 0.5 , 0 , max_speed)
	if Input.is_action_pressed("Backwards") and on_floor() and control_enabled:
		direction += _basis_f; speed = clamp(speed + 0.5 , 0 , max_speed)
	if Input.is_action_pressed("Left") and on_floor() and control_enabled:
		direction -= pivot.transform.basis.x; speed = clamp(speed + 0.5 , 0 , max_speed)
	if Input.is_action_pressed("Right") and on_floor() and control_enabled:
		direction += pivot.transform.basis.x; speed = clamp(speed + 0.5 , 0 , max_speed)

# Sprint if not running backwards, remove the elif and the "(not crouched and not Input.is_action_pressed("Backwards"))" part if you still want to be able to run backwards
	if Input.is_action_pressed("Sprint") and max_speed == 5.0 and on_floor() and control_enabled and (not crouched and not Input.is_action_pressed("Backwards")):
		max_speed = 8.5; sprinting = true
	elif Input.is_action_pressed("Backwards") :max_speed = 5.0; sprinting = false

	if not Input.is_action_pressed("Sprint") and max_speed == 8.5 and control_enabled:
		max_speed = 5.0; sprinting = false

	if Input.is_action_just_pressed("Crouch") and control_enabled and not getup_cast.is_colliding():
		crouch(not crouched)


	if Input.is_action_just_pressed("Jump") and can_jump():
		var tween = create_tween()
		tween.tween_property(self , "linear_velocity:y" , linear_velocity.y + 9.8 , 0.1)

	if not (Input.is_action_pressed("Forward") or Input.is_action_pressed("Backwards") or Input.is_action_pressed("Left") or Input.is_action_pressed("Right")) and on_floor():
		speed = clamp(speed - 0.5, 0, max_speed)
# Run animation layer
	player_tree["parameters/movement_layer/movement_layer/blend_amount"] = lerp(player_tree["parameters/movement_layer/movement_layer/blend_amount"] , ((linear_velocity.x + linear_velocity.z) / 3 + airtime) * 1.5 , 0.25)

	if direction != Vector3.ZERO and on_floor():
		direction.y = 0
		direction = direction.normalized()
		linear_velocity.x = clamp(direction.x * speed , -max_speed , max_speed)
		linear_velocity.z = clamp(direction.z * speed , -max_speed , max_speed)
	var scope_tween = create_tween()
# THe part where it does the cool fov thing.
	scope_tween.tween_property(camera , "fov" , clamp(70 + speed + linear_velocity.y , 45 , 100) , 0.25)

func can_jump() -> bool:
	if on_floor() and control_enabled: return true
	else: return false

func on_floor() -> bool:
	if floor_cast.is_colliding(): 
		return true
	else: 
		return false

func crouch(on: bool) -> void:
# true = crouch, false = stand up
	if on:
		col.shape.height = 1.25
		col.position.y = 0.5
		var tween = create_tween()
		tween.tween_property(pivot , "position:y" , 0.65 , 0.35).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

	else:
		col.shape.height = 2
		col.position.y = 1
		var tween = create_tween()
		tween.tween_property(pivot , "position:y" , 1.5 , 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

	crouched = on

	if on:
		var speedtween = create_tween(); speedtween.tween_property(self , "max_speed" , 3 , 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		var speedtween = create_tween(); speedtween.tween_property(self , "max_speed" , 5 , 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


#region Used by trigger
func pending_reset():
	set_deferred("do_fall_animation" , false)
	set_deferred("do_lightfall_animation" , false)
#endregion
