extends AnimatedSprite

onready var player = get_parent()
var frame_count : int = 0

# for scaling sprite on jump
var sprite_scale_default = scale
var sprite_scale_jump = sprite_scale_default * Vector2(1, 0.8)
var sprite_scale_fall = sprite_scale_default * Vector2(0.9, 1)

func _process(_delta):
	frame_count += 1
	sprite_animate(frame_count)


func sprite_animate(_delta) -> void:
	
	if player.input_jump() or player.input_jump_just():
		play('jump')
		scale = sprite_scale_jump
		return
	
	if player.input_jump_released():
		scale = sprite_scale_default
	
	if player.input_move_left() or player.input_left_strength() or player.input_move_right() or player.input_right_strength():
		if player.is_on_floor():
			play("run")
			return
		else:
			play('fall') # not sure if this works
			return
	
	if player._velocity.y > 400:
		play('fall')
		scale = sprite_scale_fall
		return
	else: 
		scale = sprite_scale_default
	
	# default to playing the idle animation
	play('idle')
	
	# flip sprite randomly every n frames
	var n = 120
	if frame_count % n == 0:
		var rand_bool : bool = randi() % 2 == 1
		flip_h = rand_bool
	
	return
