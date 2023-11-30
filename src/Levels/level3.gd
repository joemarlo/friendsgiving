extends Level

onready var random_scene = preload("res://scenes/randomArea.tscn")
var random_scene_global_position = Vector2(4500, 0)
var start_fixed_area = Vector2(489, 25)
var end_fixed_area = Vector2(10000, 700)
var camera_second : Camera2D
var camera_zoom_out_factor = 2.0
onready var camera_fly = get_node("CameraFly")
onready var camera_fly_end = get_node("CameraFlyEnd")

onready var turkey_scene = preload("res://scenes/turkey.tscn")
onready var doc = get_node("DocFollow/PathFollow2D/Doc")
var sprite_doc_scared = preload("res://assets/sprite/doc-scared.png")

signal doc_animation_finished(body)


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("doc_animation_finished", self, "_on_docAnimation_completed")

func _on_DeathFloor_body_entered(body):
	if body.is_in_group("players"): 
		on_player_death(0)

func _on_CutSceneLine_body_entered(body):
	if body.is_in_group("players"):
		GameManager.toggle_player_control(false)
		$CutAreas/CutSceneLine.queue_free()
		move_other_player(body)
		yield(get_tree().create_timer(2), "timeout")
		run_doc_animation(body)

func _on_FinalSceneLine_body_entered(body):
	if body.is_in_group("players"):
		GameManager.toggle_player_control(false)
		$CutAreas/FinalSceneLine.queue_free()
		
		# swap cameras
		camera_fly_end.current = true
		$CameraMain.current = false
		camera_fly_end.zoom = $CameraMain.zoom
		
		# create the tween
		var doc_follow_tween = Tween.new()
		add_child(doc_follow_tween)
		var duration = 5
		doc_follow_tween.interpolate_property(
			$DocFollow/PathFollow2D, 
			"unit_offset", 
			0.75,
			1, 
			duration, 
			Tween.TRANS_SINE, 
			Tween.EASE_IN_OUT
		)
		# TODO: not tested yet
		var zoom_level = camera_fly.zoom
		doc_follow_tween.interpolate_property(
			camera_fly, 
			"zoom", 
			zoom_level,
			zoom_level * 3, 
			duration, 
			Tween.TRANS_SINE, 
			Tween.EASE_IN_OUT
		)
		doc_follow_tween.start()
		doc_follow_tween.connect("tween_completed", self, "_on_DocPathEnd_Completed", [doc_follow_tween])


func _on_EndGameLine_body_entered(body):
	if body.is_in_group("players"):
		$CutAreas/EndGameLine.queue_free()
		$BackgroundMusic.stop()
#		$BackgroundMusic.stream = preload("res://assets/audio/wolfram-8.tres")
#		$BackgroundMusic.play()
		on_game_win()

func on_game_win(delay : float = 0.1):
	yield(get_tree().create_timer(delay), "timeout")
	success_screen('YOU SAVED DOC! the end')
	get_tree().paused = true
	yield(get_tree().create_timer(6), "timeout")
	get_tree().change_scene("res://scenes/main.tscn")
	get_tree().paused = false
	GameManager.reset_game_vars()

var docpathend_completed_has_run = false
func _on_DocPathEnd_Completed(object, key, tween):
	if not docpathend_completed_has_run:
		docpathend_completed_has_run = true
		tween.queue_free()
		$CameraMain.current = true
		camera_fly_end.current = false
		spawn_turkeys_on_stairs()
		
		$BackgroundMusic.stop()
		$BackgroundMusic.stream = preload("res://assets/audio/wolfram-7.tres")
		$BackgroundMusic.play()
		GameManager.toggle_player_control(true)

func move_other_player(body):
	var other_player
	if body.is_in_group('player1'):
		other_player = $Player2
	else:
		other_player = $Player
	
	# create the tween
	var move_tween = Tween.new()
	add_child(move_tween)
	var offset = Vector2(-50, 0)
	var duration = 1
	move_tween.interpolate_property(
		other_player, 
		"global_position", 
		other_player.global_position,
		body.global_position + offset, 
		duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	move_tween.start()
	move_tween.connect("tween_completed", self, "_on_MoveOtherPlayer_Completed", [move_tween])

func _on_MoveOtherPlayer_Completed(object, key, tween):
	tween.queue_free()

func run_doc_animation(body) -> void:
	
	spawn_turkeys_around_doc()
	
	# swap cameras
	camera_fly.current = true
	$CameraMain.current = false
	camera_fly.zoom = $CameraMain.zoom
	
	# create the tween
	var doc_follow_tween = Tween.new()
	add_child(doc_follow_tween)
	var offset_start = 0
	var offset_end = 0.75
	var duration = 10
	doc_follow_tween.interpolate_property(
		$DocFollow/PathFollow2D, 
		"unit_offset", 
		offset_start,
		offset_end, 
		duration, 
		Tween.TRANS_SINE, 
		Tween.EASE_IN_OUT
	)
	doc_follow_tween.interpolate_property(
		camera_fly, 
		"zoom", 
		camera_fly.zoom,
		camera_fly.zoom * 4, 
		duration, 
		Tween.TRANS_SINE, 
		Tween.EASE_IN_OUT
	)
	doc_follow_tween.start()
	doc_follow_tween.connect("tween_completed", self, "_on_DocPath_Completed", [doc_follow_tween, body])

var docpath_completed_has_run = false
func _on_DocPath_Completed(object, key, tween, body):
	if not docpath_completed_has_run:
		docpath_completed_has_run = true
		tween.queue_free()
		trigger_pan_and_animation(body)

func trigger_pan_and_animation(body) -> void:
	camera_second = Camera2D.new()
	camera_second.name = "CameraCutscene"
	add_child(camera_second)
	camera_second.current = true
	$CameraMain.current = false
	camera_fly.current = false
	camera_second.zoom = camera_fly.zoom
	camera_second.global_position = camera_fly.global_position
	var tween_to_duration = 5
	var tween_to_position = random_scene_global_position
	
	# tween
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(
		camera_second, 
		"global_position", 
		camera_second.global_position, 
		tween_to_position, 
		tween_to_duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween.interpolate_property(
		camera_second,
		'zoom',
		camera_second.zoom,
		camera_second.zoom * camera_zoom_out_factor,
		tween_to_duration,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween.start()
	
	# zoom tween
	tween.connect("tween_completed", self, "_on_PanToLevel_Completed", [tween, body])

var pantolevel_completed_has_run = false
func _on_PanToLevel_Completed(object, key, tween, body) -> void:
	if not pantolevel_completed_has_run:
		pantolevel_completed_has_run = true
		tween.queue_free()
		run_room_generation(body)

var new_random_area
var body_global_position
func run_room_generation(body) -> void:
	new_random_area = random_scene.instance()
	new_random_area.connect("rooms_complete", self, "_on_rooms_completed")
	new_random_area.global_position = random_scene_global_position
	body_global_position = body.global_position
	add_child(new_random_area)

func _on_rooms_completed():
	print("Rooms generation completed")
		
	# pan back to main camera
	var tween_back = Tween.new()
	add_child(tween_back)
	var tween_duration = 3
	tween_back.interpolate_property(
		camera_second,
		'global_position',
		camera_second.global_position,
		$CameraMain.global_position,
		tween_duration,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween_back.interpolate_property(
		camera_second,
		'zoom',
		camera_second.zoom,
		$CameraMain.zoom,
		tween_duration,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween_back.start()
	tween_back.connect("tween_completed", self, "_on_PanBackLevel_Completed", [tween_back])

var panbacklevel_completed_has_run = false
func _on_PanBackLevel_Completed(object, key, tween) -> void:
	if not panbacklevel_completed_has_run:
		panbacklevel_completed_has_run = true
		# swap back to main camera
		tween.queue_free()
		camera_second.current = false
		$CameraMain.current = true
		camera_second.queue_free()
		
		GameManager.toggle_player_control(true)
		emit_signal('doc_animation_finished')


func _on_docAnimation_completed() -> void:
	# draw the lines of tiles from the random area to the fixed area
	var start_room_global_position = random_scene_global_position + new_random_area.starting_room.position + Vector2(-150, 150)
	draw_line_of_tiles($TileMap, start_fixed_area, start_room_global_position)
	var end_room = random_scene_global_position + new_random_area.ending_room.position + Vector2(150, 150)
	draw_line_of_tiles($TileMap, end_room, end_fixed_area)
	
	# change background music
	$BackgroundMusic.stop()
	$BackgroundMusic.stream = preload("res://assets/audio/wolfram-6.tres")
	$BackgroundMusic.play()

func pan_camera_to_position(camera, position, duration, name = 'tween') -> Tween:
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(
		camera, 
		"global_position", 
		camera.global_position, 
		position, 
		duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween.start()
	return tween

func draw_line_of_tiles(tile_map: TileMap, global_start: Vector2, global_end: Vector2):
	var start = tile_map.world_to_map(global_start)
	var end = tile_map.world_to_map(global_end)
	
	var dx = abs(end.x - start.x)
	var dy = -abs(end.y - start.y)
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	var err = dx + dy
	
	while true:
		tile_map.set_cell(start.x, start.y, 1)
		
		if start.x == end.x and start.y == end.y:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			start.x += sx
		if e2 <= dx:
			err += dx
			start.y += sy

func spawn_turkeys_around_doc() -> void:
	var n_turkeys = 30
	for i in range(n_turkeys):
		var new_turkey = turkey_scene.instance()
		new_turkey.add_to_group("turkeys_that_chase_doc")
		doc.add_child(new_turkey)
	doc.get_node("Sprite").texture = sprite_doc_scared

func spawn_turkeys_on_stairs() -> void:
	var n_turkeys = 30
	var turkey_parent = Node2D.new()
	add_child(turkey_parent)
	turkey_parent.global_position = end_fixed_area + Vector2(400, -400)
	for i in range(n_turkeys):
		var new_turkey = turkey_scene.instance()
#		new_turkey.add_to_group("turkeys_that_chase_doc")
		turkey_parent.add_child(new_turkey)

