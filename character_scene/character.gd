extends Area2D

#	Signals
signal selected(character)

#	Private variables
var _tilemap

#	Public variables
var speed = 200
var screen_size
var player_size

#	Onready variables
onready var path_array = []
onready var path_line := get_node("PathLine")

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			emit_signal("selected", self)

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	player_size = get_node("CharacterSprite").texture.get_size()
	
	path_line.set_joint_mode(path_line.LINE_JOINT_ROUND)
	
	_tilemap = get_parent().get_node("WorldTileMap")
	get_parent().connect("character_action", self, "_on_character_action")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var velocity = Vector2()
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	position += velocity * delta


func _on_character_action(character, id, world_position):
	if character == self:
		if id == 0:
			#	Check wheter the selected tile, at the world_position, is in
			#	the path already, or not.
			if !is_point_in_path(world_position):
				if path_array.empty():
					set_player_point()
					
				#	Add the position of every tile between the selected and
				#	the last position in the path to the path, including the
				#	selected one.
				for point in _tilemap.find_path(world_position, path_array[len(path_array) - 1]):
					add_point_to_path(_tilemap.get_tile_center(point), Vector2(0, 0))
		elif id == 1:
			if is_point_in_path(_tilemap.get_tile_center(world_position)):
				remove_point_from_path(_tilemap.get_tile_center(world_position))
		elif id == 2:
			#	Check wheter or not the popup is visible, at the moment.
			#if not path_popup.visible:
					
			#travel_panel.hide()
			#if get_cellv(map_position) != INVALID_CELL:
				#travel_label.text = get_info(tile_set.tile_get_name(get_cellv(map_position)))
				# TODO: Popup appear at left upper corner if there is not enough space
				#travel_panel.popup(Rect2(event.position + Vector2(width, heigth) / 2, Vector2(100, 50)))
				
			#	Move the player for every point in the path.
			if !path_array.empty():
				for i in len(path_array):
					self.position = path_array[i]
			
			#	Clear all points in the path, erase the line.
			path_array.clear()
			path_line.clear_points()


#	Description:
#	Sets the first points in both, the path_array and the path_line.
func set_player_point():
	
	#	Set the players position as the first point, absolute to the map.
	path_array.append(self.position)
	
	#	Set the first point in the line to the center, since the path is relative
	#	to the player.
	path_line.add_point(Vector2(0, 0))


#	Values: world_position, world_popup_position; return void
#	Description:
#	Adds a point to the path at the location of the given value world_position
#	and also create a popup with details to the path.
func add_point_to_path(world_position: Vector2, world_popup_position: Vector2) -> void:
	
	#	Check wheter the world_position is a neighbour of the last point in the
	#	path or not.
	print(str(_tilemap.is_neighbour(world_position, path_array[len(path_array) - 1])) 
			+ " : NEW - " + str(world_position) + " : OLD - " + str(path_array[len(path_array) - 1]))
	if _tilemap.is_neighbour(world_position, path_array[len(path_array) - 1]):
		
		#	Add the world_position to the path.
		path_array.append(world_position)
		var path_index = len(path_array) - 1
		
		#	Locate the last direction vector and add it to the line.
		# TODO: Seems to not be working with a negative y, gotta look this up
		path_line.add_point(path_array[path_index] 
				- path_array[path_index - 1]
				+ path_line.get_point_position(path_line.get_point_count() - 1))
		
		# TODO: Calculate and alter the travel duration
		#travel_label.text = str(world_to_map(world_position))
		#travel_panel.popup(Rect2(world_popup_position, Vector2(100, 50)))


#	Values: world_position; return void
#	Description:
#	Removes a point and concat the path at this position.
func remove_point_from_path(world_position):
	print(str(world_position))
	if world_position in path_array:
		for i in (len(path_array) - path_array.find(world_position)) - 1:
			path_line.remove_point(len(path_array) - 1)
			path_array.pop_back()

#	Values: world_position; returns boolean
#	Description:
#	Checks if the given value world_position is already a point in the path.
func is_point_in_path(world_position):
	if world_position in path_array:
		return true
	return false
