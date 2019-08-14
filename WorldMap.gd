extends TileMap

onready var camera = get_node("../Camera2D")
onready var path2d = get_node("../Path2D")
onready var curve2d = path2d.get_curve()
onready var line2d = get_node("../Path2D/Line2D")

var terrainInfoPanel = PopupPanel.new()
var terrainInfoLabel = Label.new()

var width = 64
var heigth = sqrt(3) * (64 / 2)
#Walking speed is calculated by
#(normalSpeed * ((tiredness / 100) + (illness / 100) + 1) * ((density / 10) + 1 
#Event is calculated by
var tile_type = [
	{ "density": 3, "zombie": 6, "raider": 7, "survivor": 2, "name": "road" },
	{ "density": 9, "zombie": 1, "raider": 3, "survivor": 0, "name": "water" },
	{ "density": 5, "zombie": 8, "raider": 5, "survivor": 3, "name": "building" },
	{ "density": 1, "zombie": 3, "raider": 4, "survivor": 2, "name": "grass" },
	{ "density": 7, "zombie": 2, "raider": 7, "survivor": 4, "name": "mountain" },
	{ "density": 4, "zombie": 6, "raider": 10, "survivor": 1, "name": "military" },
	{ "density": 6, "zombie": 4, "raider": 8, "survivor": 4, "name": "forest" } 
]

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
				print(world_to_map(event.position + camera.position - get_viewport().size / 2))
			if event.doubleclick:
				var map_position = world_to_map(event.position + camera.position - get_viewport().size / 2)
				add_point_to_path(get_tile_center(event.position + camera.position - get_viewport().size / 2));
				#if get_cellv(map_position) != INVALID_CELL:
					#get_node("../Player").position = map_to_world(map_position)
		if event.button_index == BUTTON_RIGHT:
			if event.pressed == false:
				terrainInfoPanel.hide()
				var map_position = world_to_map(event.position + camera.position - get_viewport().size / 2)
				if get_cellv(map_position) != INVALID_CELL:
					camera.add_child(terrainInfoPanel)
					terrainInfoPanel.add_child(terrainInfoLabel)
					terrainInfoLabel.text = get_info(tile_set.tile_get_name(get_cellv(map_position)))
					terrainInfoPanel.popup(Rect2(map_to_world(map_position) + cell_size, Vector2(100, 50)))
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			camera.position -= event.relative

func _ready():
	get_node("../Player").position = map_to_world(Vector2(0, 0))
	
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
	curve2d.add_point(get_tile_center(get_node("../Player").position + Vector2(32, 32)))
	line2d.add_point(get_tile_center(get_node("../Player").position + Vector2(32, 32)))

func add_point_to_path(position):
	if curve2d.get_point_count() <= 0:
		set_player_point()
	if check_neighbours(position, curve2d.get_point_position(curve2d.get_point_count() - 1)):
		curve2d.add_point(position)
		line2d.add_point(position)

func get_info(type_id):
	var info_string = """{name}
	
	Density: {density}
	Zombie: {zombie}
	Raider: {raider}
	Survivor: {survivor}"""
	return info_string.format(tile_type[int(type_id)])

func get_density(type_id):
	return tile_type[int(type_id)].density
	
