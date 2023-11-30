extends Camera2D

onready var target = get_node("../DocFollow/PathFollow2D/Doc")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	if target:
		global_position = target.global_position
