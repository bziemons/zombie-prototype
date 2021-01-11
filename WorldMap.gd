extends TileMap

onready var camera = get_node("../Camera2D")
onready var path = get_node("../Player/Path")
onready var path_array = []
onready var path_player = path.get_curve()
onready var path_line = get_node("../Player/Path/PathLine")
onready var path_popup = get_node("../Player/Path/PathPopupMenu")
onready var travel_panel = camera.get_node("TravelLayer/TravelPanel")
onready var travel_label = camera.get_node("TravelLayer/TravelPanel/TravelLabel")

const MIN_ZOOM = 1
const MAX_ZOOM = 3.375

var starttile = Vector2(0, 0)
var timedone = 0
var lastgenerated = 0
var width = 64
var heigth = sqrt(3) * (64 / 2)
var target_camera_zoom = 1.0

# TODO: Find better solution
var last_world_position

#Walking speed is calculated by
#(normalSpeed * ((tiredness / 100) + (illness / 100) + 1) * ((density / 10) + 1 
#Event is calculated by
#?????????????
var tile_type = {
	"Road": { "density": 3, "zombie": 6, "raider": 7, "survivor": 2, "name": "Road" },
	"Water": { "density": 9, "zombie": 1, "raider": 3, "survivor": 0, "name": "Water" },
	"City": { "density": 5, "zombie": 8, "raider": 5, "survivor": 3, "name": "City" },
	"Grassland": { "density": 1, "zombie": 3, "raider": 4, "survivor": 2, "name": "Grassland" },
	"Mountain": { "density": 7, "zombie": 2, "raider": 7, "survivor": 4, "name": "Mountain" },
	"Military": { "density": 4, "zombie": 6, "raider": 10, "survivor": 1, "name": "Military" },
	"Forest": { "density": 6, "zombie": 4, "raider": 8, "survivor": 4, "name": "Forest" } 
}

var neighbours_even = [
	Vector2(1, -1), Vector2(1, 0), Vector2(0, 1),
	Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1),
]

var neighbours_odd = [
	Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(-1, 1), Vector2(-1, 0), Vector2(0, -1),
]

func _input(event):
	var world_position = event.position + camera.position - get_viewport().size / 2
	var map_position = world_to_map(world_position)
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				# Todo:	Feels kinda unresponsive sometimes, need to be overlooked
				# 		and maybe redone.
				
				#	Check wheter or not the popup is visible, at the moment.
				if !path_popup.visible:
					
				#	Check wheter the selected tile, at the world_position, is in
				#	the path already, or not.
					if !is_point_in_path(world_position):
						if path_array.empty():
							set_player_point()
							
						#	Add the position of every tile between the selected and
						#	the last position in the path to the path, including the
						#	selected one.
						for point in find_path(map_position, path_array[len(path_array) - 1]):
							add_point_to_path(get_tile_center(map_to_world(point)), event.position);
							
						
					
			if event.doubleclick:
				if is_point_in_path(world_position):
					
					# TODO: Keeps vanishing when it was opened before.
					#	Clear the popup menu first
					path_popup.clear()
					
					#	Set the menus options
					path_popup.add_item("Remove", 1)
					path_popup.add_item("other Action")
					path_popup.connect("id_pressed", self, "path_popup_choice")
					
					#	Popup the menu
					path_popup.popup()
					path_popup.set_position(world_position)
					last_world_position = world_position
				
		elif event.button_index == BUTTON_RIGHT:
			if not event.pressed:
				travel_panel.hide()
				if get_cellv(map_position) != INVALID_CELL:
					travel_label.text = get_info(tile_set.tile_get_name(get_cellv(map_position)))
					# TODO: Popup appear at left upper corner if there is not enough space
					travel_panel.popup(Rect2(event.position + Vector2(width, heigth) / 2, Vector2(100, 50)))
					
					#	Move the player for every point in the path.
					if !path_array.empty():
						for i in len(path_array):
							get_node("../Player").position = map_to_world(path_array[i])
					
					#	Clear all points in the path, erase the line.
					path_array.clear()
					path_line.clear_points()
		elif event.button_index == BUTTON_WHEEL_UP:
			if event.pressed:
				target_camera_zoom = max(target_camera_zoom * 2/3, MIN_ZOOM)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			if event.pressed:
				target_camera_zoom = min(target_camera_zoom * 3/2, MAX_ZOOM)
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			camera.position -= event.relative * camera.zoom

func _ready():
	get_node("../Player").position = map_to_world(Vector2(0, 0))
	path_line.set_joint_mode(path_line.LINE_JOINT_ROUND)
	
	clear()
	set_cellv(starttile, 0)

func _process(delta):
	timedone += delta
	if target_camera_zoom != camera.zoom.y:
		if camera.zoom.y > target_camera_zoom:
			var zoom_factor = clamp(pow(camera.zoom.y - target_camera_zoom + 2 - MIN_ZOOM, 2), 4, 32)
			camera.zoom = Vector2.ONE * max(camera.zoom.y - delta * zoom_factor, target_camera_zoom)
		else:
			var zoom_factor = clamp(pow(target_camera_zoom - camera.zoom.y + 2 - MIN_ZOOM, 2), 4, 32)
			camera.zoom = Vector2.ONE * min(camera.zoom.y + delta * zoom_factor, target_camera_zoom)
	var offs = 0.2
	while (timedone > offs):
		timedone -= offs
		generate_level(lastgenerated)
		lastgenerated += 1

func get_level_from_idx(x):
	var level = 0
	while x >= 6:
		level += 1
		x = x - (6 * level)
	return level

func generate_level(level):
	var tile = Vector2(starttile.x, starttile.y)
	for a in range(level):
		for b in range(a):
			if tile.x as int % 2 == 0:
				set_cellv(tile + Vector2(1, -1), 1)
				tile += Vector2(1, -1)
			else:
				set_cellv(tile + Vector2(1, 0), 1)
				tile += Vector2(1, 0)
		for b in range(a - 1):
			if tile.x as int % 2 == 0:
				set_cellv(tile + Vector2(1, 0), 2)
				tile += Vector2(1, 0)
			else:
				set_cellv(tile + Vector2(1, 1), 2)
				tile += Vector2(1, 1)
		for b in range(a):
			set_cellv(tile + Vector2(0, 1), 3)
			tile += Vector2(0, 1)
		for b in range(a):
			if tile.x as int % 2 == 0:
				set_cellv(tile + Vector2(-1, 0), 4)
				tile += Vector2(-1, 0)
			else:
				set_cellv(tile + Vector2(-1, 1), 4)
				tile += Vector2(-1, 1)
		for b in range(a):
			if tile.x as int % 2 == 0:
				set_cellv(tile + Vector2(-1, -1), 5)
				tile += Vector2(-1, -1)
			else:
				set_cellv(tile + Vector2(-1, 0), 5)
				tile += Vector2(-1, 0)
		for b in range(a):
			set_cellv(tile + Vector2(0, -1), 6)
			tile += Vector2(0, -1)

#	Values:map_position; returns map_position[]
#	Description:
#	Returns every neighbour of the point at the given value map_position.
func get_neighbours(map_position):
	var neighbours = []
	for i in range(6):
		if abs(map_position.x) as int % 2 == 1:
				neighbours.append(neighbours_odd[i] + map_position)
		else:
				neighbours.append(neighbours_even[i] + map_position)
	return neighbours

#	Values: new_map_position, previous_map_position; return boolean
#	Description:
#	Checks wheter or not the points at the location of both given values are
#	neighbours.
func is_neighbour(new_map_position, previous_map_position):
	var neighbours = get_neighbours(previous_map_position)
	if(neighbours.has(new_map_position)):
		return true
	else:
		return false

#deprecated
func check_neighbours(new_point, previous_point):
	for i in range(6):
		if abs(world_to_map(new_point).x) as int % 2 == 1:
			if world_to_map(new_point) + neighbours_odd[i] == world_to_map(previous_point):
				return true
		else:
			if world_to_map(new_point) + neighbours_even[i] == world_to_map(previous_point):
				return true
	return false

#	Values: world_position; return world_position
#	Description:
#	Returns the center of the tile, that is located at the given world_position.
func get_tile_center(world_position):
	return map_to_world(world_to_map(world_position)) + Vector2(width / 2, heigth / 2)

#	Description:
#	Sets the first points in both, the path_array and the path_line.
func set_player_point():
	
	#	Set the players position as the first point, absolute to the map.
	path_array.append(world_to_map(get_node("../Player").position + Vector2(32, 32)))
	
	#	Set the first point in the line to the center, since the path is relative
	#	to the player.
	path_line.add_point(Vector2(32, 32))

#	Values: world_position, world_popup_position; return void
#	Description:
#	Adds a point to the path at the location of the given value world_position
#	and also create a popup with details to the path.
func add_point_to_path(world_position, world_popup_position):
	
	#	Set the players position as the first point in the path, if the path is
	#	empty.
	if path_array.empty():
		set_player_point()
		
	#	Check wheter the world_position is a neighbour of the last point in the
	#	path or not.
	if is_neighbour(world_to_map(world_position), path_array[len(path_array) - 1]):
		
		#	Add the world_position to the path.
		path_array.append(world_to_map(world_position))
		var path_index = len(path_array) - 1
		
		#	Locate the last direction vector and add it to the line.
		# TODO: Seems to not be working with a negative y, gotta look this up
		path_line.add_point(map_to_world(path_array[path_index]) - map_to_world(path_array[path_index - 1])
		+ path_line.get_point_position(path_line.get_point_count() - 1))
		
		# TODO: Calculate and alter the travel duration
		travel_label.text = str(world_to_map(world_position))
		travel_panel.popup(Rect2(world_popup_position, Vector2(100, 50)))

#	Values: world_position; return void
#	Description:
#	Removes a point and concat the path at this position.
func remove_point_from_path(world_position):
	if world_to_map(world_position) in path_array:
		for i in len(path_array) - path_array.find(world_to_map(world_position)):
			path_line.remove_point(len(path_array) - 1)
			path_array.pop_back()

#	Values: world_position; returns boolean
#	Description:
#	Checks if the given value world_position is already a point in the path.
func is_point_in_path(world_position):
	if world_to_map(world_position) in path_array:
		return true
	return false

#	Values: selected_item; returns void
#	Description:
#	Action depending on the selected item in the path_popup. 
func path_popup_choice(selected_item):
	if selected_item == 1:
		remove_point_from_path(last_world_position)
		print("lel")


func get_info(type_name):
	var info_string = """{name}
	
	Density: {density}
	Zombie: {zombie}
	Raider: {raider}
	Survivor: {survivor}"""
	
	tile_type.get(type_name)
	return info_string.format(tile_type.get(type_name))

func get_density(type_name):
	return tile_type.get(type_name).density

func cube_to_oddq(cube):
	var col = cube.x
	var row = cube.z + (cube.x - (int(cube.x)&1)) / 2
	return Vector2(col, row)

func oddq_to_cube(hex):
	var x = hex.x
	var z = hex.y - (hex.x - (int(hex.x)&1)) / 2
	var y = -x-z
	return Vector3(x, y, z)

func offset_distance(a, b):
	var ac = oddq_to_cube(a)
	var bc = oddq_to_cube(b)
	return cube_distance(ac, bc)

func cube_distance(a, b):
	return (abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)) / 2

func find_path(start, goal):
	var path = []
	var next = start;
	path.append(next)
	
	for i in offset_distance(start, goal):
		var temp
		for neighbour in get_neighbours(next):
			if temp == null:
				temp = offset_distance(neighbour, goal)
				next = neighbour
			elif temp > offset_distance(neighbour, goal):
				temp = offset_distance(next, goal)
				next = neighbour
		path.append(next)
	path.invert()
	return path
