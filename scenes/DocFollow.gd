extends PathFollow2D

var is_camera_moving = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_camera_moving:
		var camera_cutscene = get_node_or_null("../../CameraCutscene")
		if camera_cutscene:
			camera_cutscene.global_position = $Doc.global_position

func start_moving_camera():
	is_camera_moving = true
func stop_moving_camera():
	is_camera_moving = false
