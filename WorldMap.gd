extends TileMap

onready var camera = get_node("../Camera2D")
onready var path = get_node("../Player/Path")
onready var path_curve = path.get_curve()
onready var path_line = get_node("../Player/Path/PathLine")
onready var travel_panel = camera.get_node("TravelLayer/TravelPanel")
onready var travel_label = camera.get_node("TravelLayer/TravelPanel/TravelLabel")

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
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				travel_panel.hide()
				print(world_to_map(event.position + camera.position - get_viewport().size / 2))
			if event.doubleclick:
				var map_position = world_to_map(event.position + camera.position - get_viewport().size / 2)
				add_point_to_path(get_tile_center(event.position + camera.position - get_viewport().size / 2), event.position);
				#if get_cellv(map_position) != INVALID_CELL:
					#get_node("../Player").position = map_to_world(map_position)
		if event.button_index == BUTTON_RIGHT:
			if event.pressed == false:
				travel_panel.hide()
				var map_position = world_to_map(event.position + camera.position - get_viewport().size / 2)
				if get_cellv(map_position) != INVALID_CELL:
					travel_label.text = get_info(tile_set.tile_get_name(get_cellv(map_position)))
					# TODO: Popup appear at left upper corner if there is not enough space
					travel_panel.popup(Rect2(event.position + Vector2(width, heigth) / 2, Vector2(100, 50)))
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			camera.position -= event.relative

func _ready():
	get_node("../Player").position = map_to_world(Vector2(0, 0))
	path_line.set_joint_mode(path_line.LINE_JOINT_ROUND)
	
	clear()
	var tile = Vector2(0, 0)
	set_cellv(tile, 0)
	for a in range(100):
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

func check_neighbours(new_point, previous_point):
	for i in range(6):
		if abs(world_to_map(new_point).x) as int % 2 == 1:
			if world_to_map(new_point) + neighbours_odd[i] == world_to_map(previous_point):
				return true
		else:
			if world_to_map(new_point) + neighbours_even[i] == world_to_map(previous_point):
				return true
	return false

func get_tile_center(position):
	return map_to_world(world_to_map(position)) + Vector2(width / 2, heigth / 2)

func set_player_point():
	path_curve.add_point(get_tile_center(get_node("../Player").position + Vector2(32, 32)))
	path_line.add_point(get_tile_center(get_node("../Player").position + Vector2(32, 32)))

func add_point_to_path(position, popup_position):
	if path_curve.get_point_count() <= 0:
		set_player_point()
	if check_neighbours(position, path_curve.get_point_position(path_curve.get_point_count() - 1)):
		path_curve.add_point(position)
		path_line.add_point(position)
		# TODO: Calculate and alter the travel duration
		travel_label.text = "EST. Arrival: 10 Years"
		travel_panel.popup(Rect2(popup_position, Vector2(100, 50)))

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
	
