extends Node2D

# this generates the random area based on https://kidscancode.org/blog/2018/12/godot3_procgen6/
# the room.gd script controls the individual room rects
# the scene this is a part of "randomArea.tscn" is instantiated by the level3 scene
# the rooms node is where all the little rooms are attached to
# the tilemap node is the base node this script generates the tiles to

# TODO:
# - fix extents
# - generate on demand in cutscene
# - delete tiles on far right hand side

var starting_position = Vector2(0, 0)
var turkey_scene = preload("res://scenes/turkey.tscn")
var starting_room # used by parent script
var ending_room # used by parent script

signal rooms_complete

# room generation
#var n_tries = 5	add_child(tween)
var Room = preload("res://scenes/rooms.tscn")
var tile_size = 10  # size of a tile in the TileMap
var num_rooms = 40  # number of rooms to generate
var min_size = 10  # minimum room size (in tiles)
var max_size = 20  # maximum room size (in tiles)
var hspread = 600  # horizontal spread
var cull = 0.4 # chance to cull a given room
var turkey_rate = 0.5 # chance a given room gets a turkey
var pie_rate = 0.15 # chance a given room gets a pie
var beer_rate = 0.3 # chance a given room gets a beer

# path b/t rooms generation
var path  # AStar pathfinding object

# tiles
onready var Map = $TileMap
var start_room = null
var end_room = null
var play_mode = false  
var player = null


func _ready():
	randomize()
	for i in range(3):
		make_rooms()
		yield(get_tree().create_timer(2), 'timeout')
		remove_rooms()
	create_random_world()

func _process(delta):
	update()

func _draw():
	# draw rooms
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size*2),
				  Color(0.9, 0.7, 0), false)
	
	# draw path b/t rooms
	if path:
		for p in path.get_points():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y),
						  Vector2(cp.x, cp.y),
						  Color(0.5, 0.6, 0.3, 0.8), 8, true)

#func _input(event):
#	# regenerate map
#	if event.is_action_pressed('ui_select'):
#		remove_rooms()
#		make_rooms()
#
#	# trigger tile build
#	if event.is_action_pressed('ui_focus_next'):
#		make_map()

func create_random_world() -> void:
	randomize()
	make_rooms()
	yield(get_tree().create_timer(2), 'timeout')
	make_map()
	open_up_start_room()
	open_up_end_room()
	spawn_objects()
#	yield(get_tree().create_timer(1), 'timeout')
	emit_signal("rooms_complete")
	

func position_tilemap():
	starting_room = find_start_room()
	var offset = starting_position - starting_room.position
#	GameManager.map_offset = offset
	Map.position += offset

func remove_rooms():
	for n in $Rooms.get_children():
		n.queue_free()

func make_rooms():
	for i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread, hspread), 0)
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size)
		var h = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(w, h) * tile_size)
		$Rooms.add_child(r)
	
	# wait for movement to stop
	yield(get_tree().create_timer(1.1), 'timeout')
	
	# cull rooms randomly
	# store positions of remaining rooms
	var room_positions = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(Vector3(room.position.x, room.position.y, 0))
	yield(get_tree(), 'idle_frame')
	
		# generate spanning tree (path)
	yield(get_tree().create_timer(0.4), 'timeout') # for effect
	path = find_mst(room_positions)

func find_mst(nodes):
	# Prim's algorithm
	# Given an array of positions (nodes), generates a minimum
	# spanning tree
	# Returns an AStar object
	
	# Initialize the AStar and add the first point
	var path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# Repeat until no more nodes remain
	while nodes:
		var min_dist = INF  # Minimum distance found so far
		var min_p = null  # Position of that node
		var p = null  # Current position
		# Loop through the points in the path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# Loop through the remaining nodes in the given array
			for p2 in nodes:
				# If the node is closer, make it the closest
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		# Insert the resulting node into the path and add
		# its connection
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		# Remove the node from the array so it isn't visited again
		nodes.erase(min_p)
	return path

func make_map():
	# Creates a TileMap from the generated rooms & path
	find_start_room()
	find_end_room()
	Map.clear()

	# Fill TileMap with walls and carve out empty spaces
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position-room.size,
					room.get_node("CollisionShape2D").shape.extents*2)
		full_rect = full_rect.merge(r)
	var topleft = Map.world_to_map(full_rect.position)
	var bottomright = Map.world_to_map(full_rect.end)
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Map.set_cell(x, y, 1)

	# Carve rooms and corridors
	var corridors = []  # One corridor per connection
	for room in $Rooms.get_children():
		var s = (room.size / tile_size).floor()
		var pos = Map.world_to_map(room.position)
		var ul = (room.position/tile_size).floor() - s
		for x in range(2, s.x * 2-1):
			for y in range(2, s.y * 2-1):
				Map.set_cell(ul.x+x, ul.y+y, 0)

		# Carve corridors
		var p = path.get_closest_point(Vector3(room.position.x,
									room.position.y, 0))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x, path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				carve_path(start, end)
		corridors.append(p)

func carve_path(pos1, pos2):
	# UPDATE FUNCTION FROM CHATGPT
	# Define the width of the corridor (number of tiles from the center)
	var corridor_width = 6
	
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	
	# Carve either x/y or y/x
	var x_y = pos1
	var y_x = pos2
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	
	for x in range(pos1.x, pos2.x, x_diff):
		for w in range(-corridor_width, corridor_width + 1):
			Map.set_cell(x, x_y.y + w, 0)  # Widen the corridor horizontally
	
	for y in range(pos1.y, pos2.y, y_diff):
		for w in range(-corridor_width, corridor_width + 1):
			Map.set_cell(y_x.x + w, y, 0)  # Widen the corridor vertically


# OLD METHOD FROM TUTORIAL
#func carve_path(pos1, pos2):
#	# Carves a path between two points
#	var x_diff = sign(pos2.x - pos1.x)
#	var y_diff = sign(pos2.y - pos1.y)
#	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
#	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
#	# Carve either x/y or y/x
#	var x_y = pos1
#	var y_x = pos2
#	if (randi() % 2) > 0:
#		x_y = pos2
#		y_x = pos1
#	for x in range(pos1.x, pos2.x, x_diff):
#		Map.set_cell(x, x_y.y, 0)
#		Map.set_cell(x, x_y.y+y_diff, 0)  # widen the corridor
#	for y in range(pos1.y, pos2.y, y_diff):
#		Map.set_cell(y_x.x, y, 0)
#		Map.set_cell(y_x.x+x_diff, y, 0)  # widen the corridor

func find_start_room():
	var min_x = INF
	for room in $Rooms.get_children():
		if room.position.x < min_x:
			start_room = room
			min_x = room.position.x
	
	starting_room = start_room
	return start_room
#
func find_end_room():
	var max_x = -INF
	for room in $Rooms.get_children():
		if room.position.x > max_x:
			end_room = room
			max_x = room.position.x
	
	ending_room = end_room
	return end_room

func spawn_objects() -> void:
	starting_room = find_start_room()
	var offset = starting_position - starting_room.position
	
	randomize()
	for room in $Rooms.get_children():
		spawn_light(room)
		if randf() < turkey_rate:
			spawn_turkey(room)
		if randf() < pie_rate:
			spawn_pie(room)
		if randf() < beer_rate:
			spawn_beer(room)

func spawn_turkey(room) -> void:
	var new_turkey = turkey_scene.instance()
	new_turkey.add_to_group("turkeys_in_random_map")
	new_turkey.global_position = room.global_position + Vector2(5, -5)
	add_child(new_turkey)

var light_scene = preload("res://scenes/light.tscn")
func spawn_light(room) -> void:
	var light = light_scene.instance()
	light.scale = Vector2(2.0, 2.0)
	light.global_position = room.global_position
	add_child(light) 

var beer_scene = preload("res://scenes/beer.tscn")
func spawn_beer(room) -> void:
	var beer = beer_scene.instance()
	beer.global_position = room.global_position
	add_child(beer)

var pie_scene = preload("res://scenes/pie.tscn")
func spawn_pie(room) -> void:
	var pie = pie_scene.instance()
	pie.global_position = room.global_position
	add_child(pie)

func open_up_end_room() -> void:
	var end_room = find_end_room()
	destroy_tiles_within_radius(Map, end_room.position, 20)
func open_up_start_room() -> void:
	var start_room = find_start_room()
	destroy_tiles_within_radius(Map, start_room.position, 20)
#	var offset_to_save_left_wall = Vector2(85, 0)
#	destroy_tiles_within_radius(Map, start_room.position + offset_to_save_left_wall, 20)
func destroy_tiles_within_radius(tile_map: TileMap, center_global_position: Vector2, radius: int):
	var center_tile_position = tile_map.world_to_map(center_global_position)
	
	for x in range(center_tile_position.x - radius, center_tile_position.x + radius + 1):
		for y in range(center_tile_position.y - radius, center_tile_position.y + radius + 1):
			var tile_position = Vector2(x, y)
			if tile_position.distance_to(center_tile_position) <= radius:
				tile_map.set_cellv(tile_position, -1)  # Remove the tile
				
	tile_map.update_dirty_quadrants()  # Update the tilemap to reflect changes

