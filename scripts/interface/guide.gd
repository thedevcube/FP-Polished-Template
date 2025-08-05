extends AspectRatioContainer

func guide_show() -> void:
	$Help.modulate = Color.TRANSPARENT
	$Help.visible = true
	var tween = create_tween()
	tween.tween_property($Help , "modulate" , Color.WHITE , 1).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	await get_tree().create_timer(7.5).timeout
	var tweenout = create_tween()
	tweenout.tween_property($Help , "modulate" , Color.TRANSPARENT , 1).set_ease(Tween.EASE_IN_OUT)
	await tweenout.finished
	queue_free()
