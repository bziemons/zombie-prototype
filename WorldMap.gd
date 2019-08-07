extends TileMap

func _input(event):
	if event is InputEventMouseButton:
		if event.doubleclick:
			var map_position = world_to_map(event.position)
			if get_cellv(map_position) != INVALID_CELL:
				get_node("Player").position = map_to_world(map_position)

func _ready():
	clear()
	var tile = Vector2(3, 3)
	
	set_cellv(tile, 0)
	for x in range(1000):
		if x == 0:
			set_cellv(tile + Vector2(0, -1), 0)
		elif  x == 1:
			set_cellv(tile + Vector2(0, 1), 0)
		elif x == 2:
			set_cellv(tile + Vector2(0, 2), 0)
		elif x == 3:
			set_cellv(tile + Vector2(1, 1), 0)
		elif x == 4:
			set_cellv(tile + Vector2(1, -1), 0)
		elif x == 5:
			set_cellv(tile + Vector2(0, -2), 0)