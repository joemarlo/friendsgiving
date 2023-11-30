extends Level

const cut_scene_duration = 12
var turkey_scene = preload("res://scenes/turkey.tscn")
var sprite_doc_scared = preload("res://assets/sprite/doc-scared.png")
var new_camera : Camera2D

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.show_message("hello there")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_EndArea_body_entered(body):
	if body.is_in_group("players"): 
		next_level("res://scenes/level2.tscn")

func _on_EndArea2_body_entered(body):
	if body.is_in_group("players"): 
		next_level("res://scenes/level2.tscn")

func _on_Area2D_body_entered(body):
	if body.is_in_group("players"): 
		on_player_death(0)

func _on_DeathFloor_body_entered(body):
	if body.is_in_group("players"): 
		on_player_death(0)

##### cutscene
func _on_CutSceneLine_body_entered(body):
	if body.is_in_group("players"):
		run_doc_scene()

func run_doc_scene() -> void:
	GameManager.toggle_player_control(false)
	trigger_pan_and_animation()

func trigger_pan_and_animation() -> void:
	new_camera = Camera2D.new()
	new_camera.name = "CameraCutscene"
	add_child(new_camera)
	new_camera.zoom = $CameraMain.zoom
	new_camera.global_position = $CameraMain.global_position
	new_camera.rotation = $CameraMain.rotation
	new_camera.current = true
	$CameraMain.current = false
	var tween_to_duration = cut_scene_duration * 3/12
	var tween_to = pan_camera_to_target(new_camera, $Doc, tween_to_duration)
	tween_to.connect("tween_completed", self, "_on_PanTo_Completed")

func spawn_turkeys() -> void:
	var n_turkeys = 7
	for i in range(n_turkeys):
		var new_turkey = turkey_scene.instance()
		new_turkey.global_position = $Doc.global_position
		new_turkey.add_to_group("turkeys_that_chase_doc")
		add_child(new_turkey)

func animate_run() -> void:
	var doc = $Doc
	var doc_follow_path = $DocFollow/PathFollow2D
	
	# make doc a child of the follow path
	if doc.get_parent():
		doc.get_parent().remove_child(doc)
		doc.position = Vector2.ZERO
		doc_follow_path.add_child(doc)
		doc.get_node("Sprite").texture = sprite_doc_scared
		yield(get_tree().create_timer(0.5), "timeout")
	
	var doc_follow_tween = Tween.new()
	doc_follow_path.add_child(doc_follow_tween)
	
	# add turkeys to follow path
	var turkeys = get_tree().get_nodes_in_group("turkeys_that_chase_doc")
	for turkey in turkeys:
		var relative_position_to_doc = turkey.global_position - doc.global_position
		turkey.get_parent().remove_child(turkey)
		turkey.position = relative_position_to_doc 
		doc_follow_path.add_child(turkey)
	
	# create the tween
	var offset_start = 0
	var offset_end = 1
	var duration = cut_scene_duration * 3/12
	doc_follow_tween.interpolate_property(
		doc_follow_path, 
		"unit_offset", 
		offset_start,
		offset_end, 
		duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	doc_follow_path.start_moving_camera()
	doc_follow_tween.start()
	doc_follow_tween.connect("tween_completed", self, "_on_Animation_Completed")

# this doesn't tween for some reason
func pan_camera_back_to_players() -> void:
	var tween_back_duration = cut_scene_duration * 2/12
	var tween_back = pan_camera_to_target(new_camera, $CameraMain, tween_back_duration)
	tween_back.connect("tween_completed", self, "_on_PanBack_Completed")

func _on_PanTo_Completed(tween, key) -> void:
	# duration should be cut_scene_duration * 6/10
	yield(get_tree().create_timer(cut_scene_duration * 2/12), "timeout")
	spawn_turkeys()
	GameManager.toggle_player_control(false)
	yield(get_tree().create_timer(cut_scene_duration * 2/12), "timeout")
	animate_run()

func _on_Animation_Completed(tween, key) -> void:
	pan_camera_back_to_players()

func _on_PanBack_Completed(tween, key) -> void:
	$CameraMain.current = true
	$CutSceneLine.queue_free()
	new_camera.queue_free()
	$DocFollow.queue_free()
	remove_all_turkeys()
	GameManager.toggle_player_control(true)

func pan_camera_to_target(camera, target_node, duration, name = 'tween') -> Tween:
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(
		camera, 
		"global_position", 
		camera.global_position, 
		target_node.global_position, 
		duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween.start()
	return tween

func remove_all_turkeys() -> void:
	var all_turkeys = get_tree().get_nodes_in_group("Enemies")
	for turkey in all_turkeys:
		turkey.queue_free()
