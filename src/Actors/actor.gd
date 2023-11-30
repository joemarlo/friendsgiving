extends KinematicBody2D
class_name Actor

const FLOOR_NORMAL: = Vector2.UP
const TERMINAL_VELOCITY := 700.0

var speed: = Vector2(500.0, 600.0)
var gravity: = 700.0

var _velocity: = Vector2.ZERO

func _physics_process(delta: float) -> void:
	_velocity.y += gravity * delta
	_velocity.y = min(_velocity.y, TERMINAL_VELOCITY)


func flash_sprite() -> void:
	var sprite = $Sprite
	for i in range(6):
		sprite.modulate = Color("#f25c5c")
		yield(get_tree().create_timer(0.08), "timeout")
		sprite.modulate = Color(1, 1, 1)
		yield(get_tree().create_timer(0.08), "timeout")

func freeze() -> void:
	set_physics_process(false)
	set_process(false)
