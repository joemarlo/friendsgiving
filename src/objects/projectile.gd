extends Area2D
class_name Projectile

var speed = 400
var direction: = 1 #Vector2.RIGHT
var velocity = Vector2.ZERO
var fire_angle_radians = deg2rad(-70)
var spin_speed : = float()
var spin_range = {"min": 1, "max": 8}

func _ready():
	connect("body_entered", self, "_on_Projectile_body_entered")
	velocity = Vector2(cos(fire_angle_radians), sin(fire_angle_radians)) * speed
	spin_speed = randomize_spin_speed()
	var pitch_scaled = GameManager.map_value_to_range(abs(spin_speed), spin_range.min, spin_range.max, 0.2, 0.4)
	play_audio(pitch_scaled)
	randomize_sprite()


func _physics_process(delta):
	#position += transform.x * direction * speed * delta
	velocity.y += gravity * delta * 10
	velocity.x = direction * speed
	position += velocity * delta
	
	rotation += spin_speed * delta


func _on_Projectile_body_entered(body):
	if body.is_in_group("Enemies") and body.has_method('has_been_shot'):
		body.has_been_shot()
		remove_projectile()
		return
	
	# TODO: this doesn't work
#	if body is TileMap and body.is_in_group("tile_destroyable"):
##		var map_offset = body.position  # Assuming this is the offset applied to the TileMap
##		var adjusted_global_position = global_position - map_offset
#		var local_collision_point = body.world_to_map(global_position) #adjusted_global_position)
#		body.set_cellv(local_collision_point, -1)  # -1 removes the tile
#		body.update_dirty_quadrants()  # Update to reflect the changes visually
#		remove_projectile()
#		return
#		var local_collision_point = body.world_to_map(global_position)
#		body.set_cellv(local_collision_point, -1)  # -1 removes the tile
#		body.update_dirty_quadrants()  # Update to reflect the changes visually
#		remove_projectile()
#		return


func kill_all_projectile_audio() -> void:
	for audio_player in get_tree().get_nodes_in_group('projectile-audio'):
		if audio_player.is_class("AudioStreamPlayer"):
			audio_player.stop()

func fade_out_audio(audio_player: AudioStreamPlayer, fade_out_time: float) -> void:
	var tween = $TweenAudio
	tween.interpolate_property(audio_player, "volume_db", 
							   audio_player.volume_db, -40,  # -80 dB is considered silence
							   fade_out_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	tween.connect("tween_completed", self, "_on_AudioFadeOut_Completed", [audio_player])

func _on_AudioFadeOut_Completed(object, key, audio_player: AudioStreamPlayer) -> void:
	audio_player.stop()

func play_audio(pitch) -> void:
	#kill_all_projectile_audio()
	var audio_player = $AudioStreamPlayer
	audio_player.pitch_scale = pitch
	audio_player.play()
	fade_out_audio(audio_player, 5.0) 

func randomize_sprite() -> void:
	var switch_sprite = true if randi() % 2 == 0 else false
	if switch_sprite:
		$Sprite.texture = preload("res://assets/objects/gourd.png")

func randomize_spin_speed() -> float:
	randomize()
	var rotation_direction = -1 if randi() % 2 == 0 else 1
	var spin_speed = rand_range(spin_range.min, spin_range.max) * rotation_direction
	return spin_speed

func remove_projectile() -> void:
	freeze()
	
	# Start the explosion effect by scaling the sprite
	var tween = $Tween
	var scale_factor = Vector2(0.3, 1.6)
	var tween_length_in_sec = 0.01
	tween.interpolate_property(
		$Sprite, 
		"scale",
		$Sprite.scale, 
		$Sprite.scale * scale_factor, 
		tween_length_in_sec,
		Tween.TRANS_LINEAR, 
		Tween.EASE_OUT
	)
	tween.start()
	yield(get_tree().create_timer(0.3), "timeout")
	queue_free()

func freeze() -> void:
	set_physics_process(false)
	set_process(false)
	$CollisionShape2D.disabled = true
