extends Node

var health_start : float = 100
var health : float = health_start # health is shared between players;
var map_offset : Vector2 # offset calculated after generating the random map
var level_timer : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	level_timer += delta
	pass

func reset_game_vars() -> void:
	reset_health()
	for shader in get_tree().get_nodes_in_group("levels"):
		if shader.has_method("reset_drunk_shader"):
			shader.reset_drunk_shader()

func reset_timer() -> void:
	level_timer = 0.0

##### health
func remove_health(amount) -> void:
	health -= amount
	add_camera_trauma_all(0.30)

func add_health(amount) -> void:
	health += amount
	add_camera_trauma_all(0.25)

func reset_health() -> void:
	health = health_start

##### sprites
func flash_all_player_sprites() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("flash_sprite"):
			player.flash_sprite()

func toggle_player_control(enable : = true) -> void:
	var player_nodes = get_tree().get_nodes_in_group('players')
	var enemy_nodes = get_tree().get_nodes_in_group('Enemies')
	var nodes_to_freeze = player_nodes + enemy_nodes
	for node in nodes_to_freeze:
		node.set_physics_process(enable)
		node.set_process(enable)
		node.set_process_input(enable)
		node.set_process_unhandled_input(enable)

##### camera
func add_camera_trauma_all(amount) -> void:
	var cameras = get_tree().get_nodes_in_group("cameras")
	for camera in cameras:
		if camera.has_method("add_trauma"):
			camera.add_trauma(amount)

#### messages
func show_message(text: String, duration: float = 10.0):
	var message_label = Label.new()
	message_label.text = text
	message_label.align = Label.ALIGN_CENTER
	message_label.rect_min_size = Vector2(200, 100)
	message_label.rect_position = Vector2(OS.window_size.x / 2 - 200, 50)
	message_label.rect_scale = Vector2(2, 2)
	add_child(message_label)

	# Automatically remove the label after 'duration' seconds
	yield(get_tree().create_timer(duration), "timeout")
	message_label.queue_free()


#### misc pure functions
func map_value_to_range(value, from_min, from_max, to_min, to_max):
	return to_min + (value - from_min) * (to_max - to_min) / (from_max - from_min)
func rand_between(lower : float = 0, upper : float = 1) -> float:
	return lower + randf() * (upper - lower)
