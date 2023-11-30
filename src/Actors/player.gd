extends Actor
class_name Player

# movement
var n_jumps = 0
var can_jump = false
const jump_strength : float = -1.0
var friction = Vector2(0.085, 0.0) #friction.y not implemented
const wall_friction = 0.3 # multiplier
#onready var _sprite = $AnimatedSprite

# dashing
const dash_speed = 1500
const dash_duration = 0.2
#const dash_cooldown = 1.0
var n_dashes = 0
var is_dashing = false
var dash_timer = 0.0
var sprite_scale_default = $Sprite.scale
var sprite_scale_dash = sprite_scale_default * Vector2(0.6, 1)
var particle_scene = preload("res://scenes/dashParticles.tscn")

# other
onready var camera = get_node("../CameraMain")
var is_facing_right = true
onready var 	health_label = Label.new()

# define inputs; these can be overriden by classes that inherit from here
func input_jump_just():
	return Input.is_action_just_pressed("jump")
func input_jump():
	return Input.is_action_pressed("jump")
func input_move_left():
	return Input.is_action_pressed("move_left")
func input_move_right():
	return Input.is_action_pressed("move_right")
func input_left_strength():
	return Input.get_action_strength("move_left")
func input_right_strength():
	return Input.get_action_strength("move_right")
func input_jump_released():
	return Input.is_action_just_released("jump")
func input_shoot():
	return Input.is_action_just_pressed("shoot")
func input_dash():
	return Input.is_action_just_pressed("dash")

func _ready():
	health_label.rect_global_position = Vector2(10, 10)
	add_child(health_label)
	$Sprite.play('idle')

func _process(delta):
	health_label.text = str(GameManager.health)
	flip_sprite()

func _physics_process(delta: float) -> void:
	var is_jump_interrupted: = int( input_jump_released() and _velocity.y < 0.0 )
	var direction: = get_direction()
	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL, true) 
	can_jump = can_jump()
	
	limit_position_to_camera_bounds(delta)
	determine_facing_direction()
	shoot()
	dash(delta)

# dashing
func dash(delta) -> void:
	var is_holding_direction = input_move_left() or input_move_right() or (abs(input_left_strength()) > 0) or (abs(input_right_strength()) > 0) 
	var can_dash = can_dash()
	if input_dash() and is_holding_direction and can_dash and !is_dashing:
		start_dash()
	if is_dashing:
		dash_timer += delta
		if dash_timer > dash_duration:
			end_dash()
func start_dash() -> void:
	is_dashing = true
	n_dashes += 1
	dash_timer = 0.0
	
	GameManager.add_camera_trauma_all(0.2)
	
	# animations
	$Sprite.scale = sprite_scale_dash
	var dash_particles_instance = particle_scene.instance()
	get_tree().get_root().add_child(dash_particles_instance)
	dash_particles_instance.global_position = global_position
	dash_particles_instance.emitting = true
	dash_particles_instance.direction = dash_particles_instance.direction * get_direction()
	
	# speed
	_velocity.x = dash_speed if is_facing_right else -dash_speed
	_velocity.y = 0.0
func end_dash() -> void:
	is_dashing = false
	
	# reset animatinos
	$Sprite.scale = sprite_scale_default
#	var dash_particles_instance = get_node_or_null("Particles2D") 
#	if dash_particles_instance:
#		dash_particles_instance.queue_free()
	
	# reset speed
	_velocity.x = speed.x * (1 if is_facing_right else -1)
func can_dash() -> bool:
	if is_on_floor():
		n_dashes = 0
	if n_dashes > 0:
		return false
	return true

func determine_facing_direction():
	var input_vector = Vector2.ZERO
	input_vector.x = input_right_strength() - input_left_strength()
	
	if input_vector.x != 0:
		is_facing_right = input_vector.x > 0


func limit_position_to_camera_bounds(delta) -> void:
	# Get the camera bounds
	var camera_rect = camera.get_viewport_rect()
	var camera_bounds = Rect2(camera.global_position - camera_rect.size * 0.5 * camera.zoom,
							 camera_rect.size * camera.zoom)

	# Clamp the player's position to the camera bounds
	var camera_velocity = Vector2(0,0 )
	var new_position = position + camera_velocity * delta
	new_position.x = clamp(new_position.x, camera_bounds.position.x, camera_bounds.position.x + camera_bounds.size.x)
	#new_position.y = clamp(new_position.y, camera_bounds.position.y, camera_bounds.position.y + camera_bounds.size.y)

	# Set the player's position to the new clamped position
	position = new_position


func get_direction() -> Vector2:
	var direction_x: = int (input_right_strength() - input_left_strength() )
	var direction_y: = jump_strength if input_jump_just() and can_jump else 0.0 # this is the jump
	
	return Vector2(direction_x, direction_y)


func can_jump() -> bool:
	n_jumps += int( input_jump_just() )
	n_jumps = 0 if is_on_floor() else n_jumps
	n_jumps = 1 if wall_hold() else n_jumps
	can_jump = is_on_floor() \
		or wall_hold() \
		or (n_jumps < 2)
	return can_jump


func wall_hold() -> bool:
	return is_on_wall() and \
		(input_move_left() or \
		input_move_right()) #or \
#		Input.is_action_pressed("wall_hold"))


func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: Vector2,
		speed: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
	var out: = linear_velocity
	out.x = lerp(out.x, speed.x * direction.x, friction.x)
	
	if !is_dashing:
		out.y += gravity * get_physics_process_delta_time()
		if direction.y != 0.0:
			out.y = speed.y * direction.y
		if is_jump_interrupted:
			out.y = 0.0
	
#	out.y += gravity * get_physics_process_delta_time()
#	if direction.y != 0.0:
#		out.y = speed.y * direction.y
#	if is_jump_interrupted:
#		out.y = 0.0
	if is_on_floor():
		out.x = out.x * 1.02 # go slightly faster when on the ground
	if wall_hold():
		var _wall_friction = 1 if input_jump() else wall_friction
		out.y = out.y * _wall_friction
	return out


func calculate_stomp_velocity(linear_velocity: Vector2, impulse: float) -> Vector2:
	var out: = linear_velocity
	out.y = -impulse
	return out

### shooting
var projectile_scene = preload("res://scenes/projectile.tscn")
var can_shoot = true
var shoot_cooldown_default = 0.3 
var shoot_cooldown = shoot_cooldown_default
func shoot_projectile():
	var projectile = projectile_scene.instance()
	var offset = Vector2(0, -40)
	projectile.transform = self.global_transform
	projectile.position = projectile.position + offset
	projectile.direction = 1 if is_facing_right else -1
	#projectile.direction = Vector2.RIGHT if is_facing_right else Vector2.LEFT
	owner.add_child(projectile)
func shoot():
	# shooting
	if input_shoot() and can_shoot:
		shoot_projectile()
		can_shoot = false
		yield(get_tree().create_timer(shoot_cooldown), "timeout")
		can_shoot = true


func flip_sprite() -> void:
	if input_move_left():
		$Sprite.flip_h = true
	elif input_move_right():
		$Sprite.flip_h = false

func add_speed() -> void:
	speed = speed * Vector2(1.04, 1.04)
func remove_speed() -> void:
	speed = speed / Vector2(1.04, 1.04)

func drink() -> void:
	camera.add_drunkiness()
	
	# add speed to all players
	var players = get_tree().get_nodes_in_group('players')
	for player in players:
		player.add_speed()
	
	# increase black vignette and aberration
	var levels = get_tree().get_nodes_in_group('levels')
	for level in levels:
		if level.has_method("update_drunk_vignette"):
			level.update_drunk_vignette(0.2)
		if level.has_method("update_drunk_shader"):
			level.update_drunk_shader(0.005)
	
	# decrease shot cooldown
	shoot_cooldown = shoot_cooldown * 0.8

func sober_up() -> void:
	
	camera.decrease_drunkiness()
	
	# add speed to all players
	var players = get_tree().get_nodes_in_group('players')
	for player in players:
		player.remove_speed()
	
	# dncrease black vignette and aberration
	var levels = get_tree().get_nodes_in_group('levels')
	for level in levels:
		if level.has_method("update_drunk_vignette"):
			level.update_drunk_vignette(-0.2)
		if level.has_method("update_drunk_shader"):
			level.update_drunk_shader(-0.005)
	
	# incrase shot cooldown
	shoot_cooldown = shoot_cooldown / 0.8
