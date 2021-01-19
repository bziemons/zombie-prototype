extends TileMap

signal character_action(character, action_id, map_position)

const MIN_ZOOM = 1
const MAX_ZOOM = 3.375

var _selected_character: Node2D
var _world_position: Vector2

var starttile = Vector2(0, 0)
var timedone = 0
var lastgenerated = 0
var target_camera_zoom = 1.0
var width = 64
var heigth = sqrt(3) * (64 / 2)

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
	"Forest": { "density": 6, "zombie": 4, "raider": 8, "survivor": 4, "name": "Forest" },
}

var neighbours_even = [
	Vector2(1, -1),
	Vector2(1, 0),
	Vector2(0, 1),
	Vector2(-1, 0),
	Vector2(-1, -1),
	Vector2(0, -1),
]

var neighbours_odd = [
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(0, 1),
	Vector2(-1, 1),
	Vector2(-1, 0),
	Vector2(0, -1),
]

onready var camera := get_node("../Camera2D")
onready var popup_menu = get_node("../PopupMenu") 
onready var travel_panel := camera.get_node("TravelLayer/TravelPanel")
onready var travel_label := camera.get_node("TravelLayer/TravelPanel/TravelLabel")

func _input(event):
	_world_position = event.position + camera.position - get_viewport().size / 2
	var map_position = world_to_map(_world_position)
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and event.pressed:
			print("works")
			#	Clear the popup menu first
			popup_menu.clear()
			
			#	Set the menu options
			popup_menu.add_item("Add to path", 0)
			popup_menu.add_item("Remove till here", 1)
			popup_menu.add_item("Move", 2)
			popup_menu.add_item("Details", 3)
			
			if _selected_character == null:
				popup_menu.set_item_disabled(0, true)
				popup_menu.set_item_disabled(1, true)
				popup_menu.set_item_disabled(2, true)
			
			popup_menu.connect("id_pressed", self, "_on_id_pressed")
			
			#	Popup the menu
			popup_menu.popup()
			popup_menu.set_position(_world_position)
				
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
	var character = get_node("../Character")
	character.position = map_to_world(Vector2(0, 0)) + Vector2(width / 2, heigth / 2)
	character.connect("selected", self, "_on_character_selected")
	
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


#	Values: character; returns bool
#	Description:
#	Save the clicked character as the selected character and return true, if it
#	was successful.
func _on_character_selected(character: Node2D) -> bool:
	print("signal received")
	if not character == null:
		print("Character is now: " + character.to_string())
		_selected_character = character
		return true
	return false


#	Values: map_position; returns map_position[]
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
func is_neighbour(new_world_position, previous_world_position):
	var neighbours = get_neighbours(world_to_map(previous_world_position))
	if(neighbours.has(world_to_map(new_world_position))):
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
func get_tile_center(world_position: Vector2) -> Vector2:
	return map_to_world(world_to_map(world_position)) + Vector2(width / 2, heigth / 2)


#	Values: selected_item; returns void
#	Description:
#	Action depending on the selected item in the path_popup. 
func _on_id_pressed(id: int):
	if id == 0:
		emit_signal("character_action", _selected_character, 0, popup_menu.rect_position)
	elif id == 1:
		emit_signal("character_action", _selected_character, 1, popup_menu.rect_position)
	elif id == 2:
		emit_signal("character_action", _selected_character, 2, popup_menu.rect_position)


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
	var next = world_to_map(start);
	path.append(map_to_world(next))
	
	for i in offset_distance(world_to_map(start), world_to_map(goal)):
		var temp
		for neighbour in get_neighbours(next):
			if temp == null:
				temp = offset_distance(neighbour, world_to_map(goal))
				next = neighbour
			elif temp > offset_distance(neighbour, world_to_map(goal)):
				temp = offset_distance(next, world_to_map(goal))
				next = neighbour
		path.append(map_to_world(next))
	path.invert()
	return path
