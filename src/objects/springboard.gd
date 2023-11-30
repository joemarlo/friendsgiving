extends Area2D
class_name Springboard

var spring_force = 700
onready var sprite_scale_default = $Sprite.scale

func _ready():
	connect("body_entered", self, "_on_Springboard_body_entered")

func _on_Springboard_body_entered(body):
	if body.is_in_group("players"):
		body._velocity.y = -spring_force
		body.n_jumps = 0 # renables double jumping ability
		animate_spring()

func animate_spring() -> void:
	var tween = Tween.new()
	add_child(tween)
	var scale_starting = $Sprite.scale
	var tween_length_in_sec = 0.2

	# Scale down (compress the spring)
	tween.interpolate_property($Sprite, "scale", scale_starting, scale_starting * Vector2(1.0, 0.3), 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")

	# Scale up (release the spring)
	tween.interpolate_property($Sprite, "scale", $Sprite.scale, scale_starting * Vector2(1.05, 1.2), 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")

	# Return to normal scale
	tween.interpolate_property($Sprite, "scale", $Sprite.scale, scale_starting, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	tween.queue_free()

