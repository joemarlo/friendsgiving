extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_Beer_body_entered")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Beer_body_entered(body):
	if body.is_in_group("players") and body.has_method('drink'):
		body.drink()
		$AudioStreamPlayer2D.play()
		remove_beer()



func remove_beer() -> void:
	# Start the explosion effect by scaling the sprite
	var tween = $Tween
	var scale_factor = Vector2(1.5, 1.5)
	var tween_length_in_sec = 0.2
	tween.interpolate_property(
		$Sprite, 
		"scale",
		$Sprite.scale, 
		$Sprite.scale / scale_factor, 
		tween_length_in_sec,
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	tween.start()
	yield(get_tree().create_timer(0.3), "timeout")
	queue_free()
