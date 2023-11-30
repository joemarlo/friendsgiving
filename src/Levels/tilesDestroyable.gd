extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#tile_destroyable

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_Springboard_body_entered")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
