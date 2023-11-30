extends Camera2D
class_name MultiPlayerCamera

# add small screen shake on jump
# https://kidscancode.org/godot_recipes/2d/screen_shake/

onready var player1 = get_node("../Player")
onready var player2 = get_node("../Player2")

export var decay = 0.8  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).
export (NodePath) var target  # Assign the node this camera will follow.
var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

var zoom_min = Vector2(0.9, 0.9)
var zoom_max = Vector2(1.2, 1.2)
var zoom_speed = 2

onready var noise = OpenSimplexNoise.new()
var noise_y = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.period = 4
	noise.octaves = 2

func _process(delta):
	
	# calculate camera midpoint b/t the two players
	var midpoint = (player1.global_position + player2.global_position) / 2
	
	# apply trauma-based shake
	if target:
		global_position = get_node(target).global_position
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
	
	# set the global position after the shake
	global_position = midpoint
	
	# add drunkiness effect
	drink()
	
	# calculate and apply zoom
	var distance = player1.global_position.distance_to(player2.global_position)
	var desired_zoom = zoom_min.linear_interpolate(zoom_max, distance / 1000)
	zoom = zoom.linear_interpolate(desired_zoom, zoom_speed * delta)
	
	# add offset
	offset_h = 1
	offset_v = -1.2

func drink():
	if is_drunken_effect:
		var sway_x = sin(OS.get_ticks_msec() / 1000.0 * drunkenness_frequency) * drunkenness_intensity
		var sway_y = cos(OS.get_ticks_msec() / 1000.0 * drunkenness_frequency) * drunkenness_intensity
		var rotation_jitter = rand_range(-0.05, 0.05) * drunkenness_intensity
		position += Vector2(sway_x, sway_y)
		rotation += rotation_jitter

func add_drunkiness():
	add_trauma(0.5)
	is_drunken_effect = true
	drunkenness_intensity += 6
	drunkenness_frequency += 0.8
func decrease_drunkiness():
	drunkenness_intensity -= 6
	drunkenness_frequency -= 0.8	
	drunkenness_intensity = clamp(drunkenness_intensity, 0, INF)
	drunkenness_frequency = clamp(drunkenness_frequency, 0, INF)
func stop_drunkiness():
	is_drunken_effect = false
	drunkenness_intensity = 0
	drunkenness_frequency = 0
	
var drunkenness_intensity = 0 #10.0
var drunkenness_frequency = 0 #5.0
var is_drunken_effect : bool = true

func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed*2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed*3, noise_y)
	
func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)
	Input.start_joy_vibration(0, 1, 0, amount / 3)
