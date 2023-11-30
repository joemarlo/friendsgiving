extends CanvasLayer


# controls the shader
onready 	var color_rect = $ShaderContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	color_rect.rect_position = Vector2(0, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	color_rect.rect_min_size = get_viewport().get_visible_rect().size
	
