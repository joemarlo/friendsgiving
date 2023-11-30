extends Node2D
class_name Level

# TODO: move this to a function
onready var color_rect = $RedVignette/ColorRect #create_vignette_node()
onready var color_rect_black = $BlackVignette/ColorRect #create_vignette_node()
var vignette_curve = preload("res://resources/vignette_curve.tres")
var scale_factor_black_default = 1 # starting value of vignette 1 -> 0
var scale_factor_black = scale_factor_black_default
onready var shader = $Shader/ShaderContainer
onready var shader_aberration_default = shader.material.get_shader_param("aberration")

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.reset_timer()
	fade_in_screen()
	
	# red health vignette
	add_vignette(color_rect, vignette_curve)
	
	# black drunk vignette
	# this vignette is too subtle
	if color_rect_black:
		add_vignette(color_rect_black, vignette_curve, Color(0, 0, 0, 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var max_health : float = 100
	var scale_factor = GameManager.health / max_health
	update_vignette(color_rect, vignette_curve, scale_factor)
	if color_rect_black:
		update_vignette(color_rect_black, vignette_curve, scale_factor_black)
	is_player_dead()

func update_drunk_vignette(amount) -> void:
	scale_factor_black = scale_factor_black - amount
	scale_factor_black = clamp(scale_factor_black, 0, 1)

func update_drunk_shader(amount : float = 0.001) -> void:
	var current_amount = shader.material.get_shader_param("aberration") 
	var new_amount = clamp(current_amount + amount, 0, 1)
	shader.material.set_shader_param("aberration", new_amount)

func reset_drunk_shader() -> void:
	shader.material.set_shader_param("aberration", 0)
	scale_factor_black = scale_factor_black_default

#### transitions
func is_player_dead():
	if GameManager.health <= 0:
		on_player_death()

func on_player_death(delay : float = 0.1):
	yield(get_tree().create_timer(delay), "timeout")
	get_tree().paused = true
	death_screen()
	yield(get_tree().create_timer(5), "timeout")
	get_tree().reload_current_scene()
	get_tree().paused = false
	GameManager.reset_game_vars()

func next_level(next_scene_path):
	success_screen()
	get_tree().paused = true
	yield(get_tree().create_timer(6), "timeout")
	get_tree().change_scene(next_scene_path)
	get_tree().paused = false
	GameManager.reset_game_vars()

#### screens
func fade_in_screen(duration : float = 1, reverse : bool = false) -> void:
	# add overlay
	var color = Color(0, 0, 0, 0) if reverse else Color(0, 0, 0, 0.9) 
	var canvas_layer = create_fullscreen_overlay(color)
	var color_rect = canvas_layer.get_child(0)
	
	# add to tree and prevent pause
	add_child(canvas_layer)
	canvas_layer.pause_mode = Node.PAUSE_MODE_PROCESS
	
	# animate with tween
	var tween = Tween.new()
	canvas_layer.add_child(tween)
	
	# Move the sprite to the left
	tween.interpolate_property(
		color_rect, 
		"color",
		color_rect.color,
		Color(0, 0, 0, 1) if reverse else Color(0, 0, 0, 0),
		duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	
	# Start the tween and add callback signal
	tween.start()
	tween.connect('tween_all_completed', self, '_on_tween_all_completed',  [ canvas_layer ])

func _on_tween_all_completed(canvas_layer):
	canvas_layer.queue_free()

func success_screen(label_message = 'SUCCESS!') -> void:
	# add overlay
	var canvas_layer = create_fullscreen_overlay(Color(0.05, 0.4, 0.25, 0.8))
	
	# add label
	var label = Label.new()
	label.text = label_message + " | Time: " + str(round(GameManager.level_timer*100)/100)
	label.anchor_left = 0.5
	label.anchor_top = 0.3
	label.anchor_right = 0.5
	label.anchor_bottom = 0.7
	canvas_layer.add_child(label)
	
	# add sprites
	var sprite = Sprite.new()
	sprite.texture = load("res://assets/sprite/player-llama.png")
	sprite.position = Vector2(OS.window_size.x * 1/5, OS.window_size.y * 4/5)
	sprite.scale = Vector2(0.25, 0.25)
	canvas_layer.add_child(sprite)
	
	# add to tree and prevent pause
	add_child(canvas_layer)
	canvas_layer.pause_mode = Node.PAUSE_MODE_PROCESS
	
	# animate with tween
	var tween = Tween.new()
	canvas_layer.add_child(tween)
	
	# Move the sprite to the left
	tween.interpolate_property(
		sprite, 
		"position",
		sprite.position, 
		sprite.position + Vector2(700, 0),
		9, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween.start()
	
	# fade out screen
	fade_in_screen(7, true)

func death_screen() -> void:
	# add overlay
	var canvas_layer = create_fullscreen_overlay(Color(1, 0, 0, 0.1))
	
	# add label
	var label = Label.new()
	label.text = "YOU DED"
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	
	canvas_layer.add_child(label)
	add_child(canvas_layer)

func create_fullscreen_overlay(color):
	var canvas_layer = CanvasLayer.new() 
	var color_rect = ColorRect.new() 
	color_rect.rect_min_size = get_viewport_rect().size
	color_rect.color = color
	canvas_layer.add_child(color_rect)
	
	return canvas_layer

### vignette | these require the RedVignette.tsnc in the root of the scene
func add_vignette(color_rect, vignette_curve, color = Color(1, 0, 0, 0)) -> void:
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://src/shaders/vignette.shader")
	color_rect.rect_min_size = get_viewport_rect().size
	color_rect.color = color
	color_rect.material = shader_material
	update_vignette(color_rect, vignette_curve, 1)

func update_vignette(color_rect, vignette_curve, scale_amount) -> void:
	var health_percentage : float = scale_amount #GameManager.health / max_health
	health_percentage = clamp(health_percentage, 0.0, 1.0)
	var curve_value = vignette_curve.interpolate_baked(health_percentage)
	
	var base_intensity = 0.3 
	var max_intensity = 0.8 
	var base_alpha = 0.0
	var max_alpha = 0.3
	
	var intensity = base_intensity + curve_value * (max_intensity - base_intensity)
	var alpha = base_alpha + curve_value * (max_alpha - base_alpha)
	
	color_rect.material.set_shader_param("intensity", intensity)
	color_rect.material.set_shader_param("alpha", alpha)

#func create_vignette_node():
#	var canvas_layer = create_fullscreen_overlay(Color(0.05, 0.4, 0.25, 0.8))
#	var canvas_layer = CanvasLayer.new() 
#	var color_rect = ColorRect.new() 
#	color_rect.rect_min_size = scene.get_viewport().get_visible_rect().size * 10
#	#color_rect_death.color = Color(1, 0, 0, 0.1) 
#	color_rect.visible = true
#	canvas_layer.add_child(color_rect)
#	scene.add_child(canvas_layer)

#	return(canvas_layer.get_child(0))
