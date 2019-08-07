extends TileMap

func _input(event):
	if event is InputEventMouseButton:
		if event.doubleclick:
			var map_position = world_to_map(event.position)
			if get_cellv(map_position) != INVALID_CELL:
				get_node("Player").position = map_to_world(map_position)
