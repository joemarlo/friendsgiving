extends RigidBody2D

# https://kidscancode.org/blog/2018/12/godot3_procgen6/
# default gravity needs to be 0; was 98
# Mode of Room node needs to be 'Character' to prevent rotation

var size

func make_room(_pos, _size):
	position = _pos
	size = _size
	var s = RectangleShape2D.new()
	s.custom_solver_bias = 0.75 # this speeds up the rooms settling into their positions
	s.extents = size
	$CollisionShape2D.shape = s
	
	# make sure rooms don't collide with player
	collision_layer = 1 << 2  # This puts the object in layer 3
	collision_mask = 1 << 2  # This allows collision with objects in layer 3
