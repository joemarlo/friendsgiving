extends Actor
class_name Turkey

onready var player1 = get_tree().get_nodes_in_group('player1')[0] #get_node("../Player")
onready var player2 = get_tree().get_nodes_in_group('player2')[0] #get_node("../Player2")

var speed_turkey = speed * Vector2(0.3, 0.6)

var chase_distance = 300
var direction = Vector2()
var frame_count = 0
var update_frequency = 15  # Update every n frames
var bounce_strength = -100

# signals
func _ready():
	randomize()
	shuffle_starting_position()
	$CollisionDetector.connect("body_entered", self, "_on_turkeyCollision_body_entered")
	$StompDetector.connect("body_entered", self, "_on_turkeyStomp_body_entered")
	modulate = random_color()

func _physics_process(delta):
	var target = get_closest_player()
	var distance_to_player = global_position.distance_to(target.global_position)
	
	flip_sprite()
	
	if distance_to_player < chase_distance:
		# expand chase distance when engaged
		chase_distance = 500
		
		# add randomness every n frames (otherwise its jittery)
		frame_count += 1
		if frame_count % update_frequency == 0:  # Check if it's time to update
			var target_direction = global_position.direction_to(target.global_position)
			randomize()
			direction = target_direction.linear_interpolate(
				target_direction.rotated(rand_range(-0.2, 0.2)), 
				rand_range(0.3, 1.8) 
			)
		
		# Move the enemy and check for collisions
		var collision_info = move_and_collide(direction.normalized() * speed_turkey * delta)
		if collision_info:
			if collision_info.collider.is_in_group("players"):
				# Reflect the velocity vector on the collision normal
				direction = direction.bounce(collision_info.normal).normalized()
				move_and_collide(direction * bounce_strength * delta)
		#move_and_slide(direction.normalized() * speed_turkey)
	else:
		chase_distance = 300

func _on_turkeyCollision_body_entered(body):
	if body.is_in_group("players"):
		GameManager.remove_health(10)
		GameManager.flash_all_player_sprites()
func _on_turkeyStomp_body_entered(body):
	if body.is_in_group("players"):
		$Sprite.scale = $Sprite.scale * Vector2(1, 0.6)
		has_been_shot()

func get_closest_player():
	var distance_to_player1 = global_position.distance_to(player1.global_position)
	var distance_to_player2 = global_position.distance_to(player2.global_position)
	
	if distance_to_player1 < distance_to_player2:
		return player1
	elif distance_to_player2 < distance_to_player1:
		return player2
	else:
		return null  # No player is within the chase distance

#var enemy_scene = preload("res://path/to/your/Enemy.tscn")

func shuffle_starting_position():
	var random_x = rand_range(-300, 300)
	var random_y = rand_range(-200, 200)
	self.position += Vector2(random_x, random_y)

func has_been_shot() -> void:
	GameManager.add_health(20)
	$AudioStreamPlayer2D.play()
	freeze()
	flash_sprite()
	yield(get_tree().create_timer(1), "timeout")
	queue_free()

func flip_sprite() -> void:
	if direction.x < 0:
		$Sprite.flip_h = true 
	elif direction.x > 0:
		$Sprite.flip_h = false

func rand_between(lower : float = 0, upper : float = 1) -> float:
	return lower + randf() * (upper - lower)
func random_color() -> Color:
	return Color(
		GameManager.rand_between(0.5, 1.0), 
		GameManager.rand_between(0.5, 1.0), 
		GameManager.rand_between(0.5, 1.0), 
		1
	)
