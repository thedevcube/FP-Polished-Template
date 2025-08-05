extends RigidBody3D

@export var camera: Camera3D
@export var col: CollisionShape3D
@export var mouse_sensitivity := 0.002
@export var pivot: Marker3D ## Pivot is like a neck, for the camera
@export var floor_cast: ShapeCast3D
@export var getup_cast: RayCast3D
@export var player: AnimationPlayer

var speed = 0.0
var max_speed = 5.0
var mouse_speed := Vector2.ZERO
var fall_multiplier = 1.0
var crouched := false
var sprinting := false
var airtime := 0.0
var control_enabled := true
var do_fall_animation := false
var do_lightfall_animation := false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_speed = event.relative
	if Input.is_key_pressed(KEY_Z):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if on_floor() and (do_fall_animation or do_lightfall_animation):
		crouch(false)
		$AudioStreamPlayer3D.play()
		var finished = func(_animname):
			control_enabled = true
			$AudioStreamPlayer3D.stop()
		var tween = create_tween()
		tween.tween_property(pivot , "rotation:x" , 0 , 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		if do_fall_animation: player.play("impact" ,0.1)
		elif do_lightfall_animation:
			player.play("impact_light" ,0.1)
			
		do_fall_animation = false
		do_lightfall_animation = false
		player.animation_finished.connect(finished)

	if (mouse_speed.length() > 0.01) and control_enabled: 
		pivot.rotation.y = (pivot.rotation.y + -mouse_speed.x * mouse_sensitivity)
		pivot.rotation.x = (clamp(pivot.rotation.x - mouse_speed.y * mouse_sensitivity, deg_to_rad(-89), deg_to_rad(89)))
		mouse_speed = mouse_speed.cubic_interpolate(Vector2.ZERO , mouse_speed , Vector2.ZERO , 0.2)

func _physics_process(delta: float) -> void:
	if linear_velocity.y < 0 and not on_floor(): airtime += delta
	else: airtime = 0
	if airtime > 2: do_fall_animation = true; control_enabled = false; do_lightfall_animation = false
	if airtime > 1: do_lightfall_animation = true

	if linear_velocity.y != 0.0 and not on_floor():
		pivot.rotation.x += clamp(deg_to_rad(linear_velocity.y / 50), deg_to_rad(-25), deg_to_rad(25))

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

	if Input.is_action_pressed("Sprint") and max_speed == 5.0 and on_floor() and control_enabled:
		max_speed = 8.5; sprinting = true
	if not Input.is_action_pressed("Sprint") and max_speed == 8.5 and control_enabled:
		max_speed = 5.0; sprinting = false

	if Input.is_action_just_pressed("Crouch") and control_enabled:
		crouch(not crouched)

	if Input.is_action_just_pressed("Jump") and can_jump() and control_enabled:
		var tween = create_tween()
		tween.tween_property(self , "linear_velocity:y" , linear_velocity.y + 9.8 , 0.1)

	if not (Input.is_action_pressed("Forward") or Input.is_action_pressed("Backwards") or Input.is_action_pressed("Left") or Input.is_action_pressed("Right")) and on_floor():
		speed = clamp(speed - 0.5, 0, max_speed)

	if direction != Vector3.ZERO and on_floor():
		direction.y = 0
		linear_velocity.x = direction.x * speed
		linear_velocity.z = direction.z * speed
	var scope_tween = create_tween()
	scope_tween.tween_property(camera , "fov" , clamp(70 + speed + linear_velocity.y , 45 , 100) , 0.25)

	if linear_velocity.y < -0.1 and not on_floor():
		linear_velocity.y = linear_velocity.y - fall_multiplier * delta
		fall_multiplier += 1
		airtime += delta
	else: fall_multiplier = 1; airtime = 0.0

func can_jump() -> bool:
	if on_floor(): return true
	else: return false

func on_floor() -> bool:
	if floor_cast.is_colliding(): return true
	else: return false

func crouch(on: bool) -> void:
	if on:
		col.shape.height = 1.25
		col.position.y = 0.5
		var tween = create_tween()
		tween.tween_property(pivot , "position:y" , 0.65 , 0.35).set_ease(Tween.EASE_IN_OUT)

	elif not getup_cast.is_colliding():
		col.shape.height = 2
		col.position.y = 1
		var tween = create_tween()
		tween.tween_property(pivot , "position:y" , 1.5 , 0.5).set_ease(Tween.EASE_IN_OUT)
	crouched = on
