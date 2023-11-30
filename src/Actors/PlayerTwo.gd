extends Player


# Called when the node enters the scene tree for the first time.
func _ready():
	# change sprite
	#SpriteOld.texture = preload("res://assets/sprite/llama.png")
	$Sprite.frames = preload("res://resources/sprite-llama.tres")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# overrides controls from parent class
func input_jump_just():
	return Input.is_action_just_pressed("jump_2")
func input_jump():
	return Input.is_action_pressed("jump_2")
func input_move_left():
	return Input.is_action_pressed("move_left_2")
func input_move_right():
	return Input.is_action_pressed("move_right_2")
func input_left_strength():
	return Input.get_action_strength("move_left_2")
func input_right_strength():
	return Input.get_action_strength("move_right_2")
func input_jump_released():
	return Input.is_action_just_released("jump_2")
func input_shoot():
	return Input.is_action_just_pressed("shoot_2")
func input_dash():
	return Input.is_action_just_pressed("dash_2")
