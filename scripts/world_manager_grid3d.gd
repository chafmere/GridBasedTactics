extends Node3D

@export var _camera: Camera3D
@export var character_node: Node3D
@export var map: MeshInstance3D
@export var path_3d: Path3D
@export var show_debug: bool = false

@export var grid_step_size: Vector3 = Vector3(1,.5,1)
@export var offset: Vector2 = Vector2(0,0)

const WORLD_FINDER = preload("res://objects/world_finder.tscn")
@onready var world_points: Node3D = $WorldPoints
@onready var turn_controller: Node = $TurnController

var a_star3d: AStarGrid3D= AStarGrid3D.new()
var point_list: Dictionary
var current_grid_id: int = 0
var selected_move_grid_id: int = -1
var selected_attack_grid_id: int = -1
var active_character: CharacterBody3D
var active_selection_move_list: Array[int]
var active_selection_attack_list: Array[int]
var grid_size: Rect2i

func _ready() -> void:
	get_grid_size(map)
	build_point_list()
	build_a_star_grid3d(point_list)
	connect_points(point_list)
	build_character_list()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.get_button_index() == MOUSE_BUTTON_LEFT and event.pressed:
			var id = get_grid_map_id()
			if active_selection_move_list.has(id):
				select_grid_id_for_move(id)
			elif active_selection_attack_list.has(id):
				select_grid_id_for_attack(id)
					
	if event is InputEventMouseMotion:
		var id = get_grid_map_id()
		set_current_grid_id(id)

func select_grid_id_for_move(id) -> void:
	if selected_move_grid_id != -1:
		point_list[selected_move_grid_id].indicator.unselected()
		
	selected_move_grid_id = id
	var from_id: int = active_character.current_position_key
	point_list[selected_move_grid_id].indicator.selected()
	visualise_path(from_id, selected_move_grid_id)
	
func select_grid_id_for_attack(id) -> void:
	if selected_attack_grid_id != -1:
		point_list[selected_attack_grid_id].indicator.unselected()
		
	selected_attack_grid_id = id
	point_list[selected_attack_grid_id].indicator.selected()

func get_grid_size(_grid_mesh: MeshInstance3D) -> void:
	var _grid_aabb: AABB = _grid_mesh.get_aabb()
	grid_size = Rect2i(int(_grid_aabb.position.x),int(_grid_aabb.position.z),int(_grid_aabb.size.x),int(_grid_aabb.size.z))

func get_grid_map_id() -> int:
	var mouse_pos: Vector3
	
	var viewport: Viewport = get_viewport()
	var mouse_position: Vector2 = viewport.get_mouse_position()
	
	var _start_point: Vector3 = _camera.project_ray_origin(mouse_position)
	var _end_point: Vector3 = (_start_point + _camera.project_ray_normal(mouse_position) * 100)
	
	var new_ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(_start_point, _end_point)
	new_ray_query.set_collision_mask(0b00001)
	var new_ray: Dictionary = get_world_3d().direct_space_state.intersect_ray(new_ray_query)
	var grid_pos_index: int
	if new_ray:
		mouse_pos = new_ray.position
		grid_pos_index = a_star3d.get_closest_point(mouse_pos)

		
	return grid_pos_index
	
func build_character_list() -> void:
	for c: CharacterBody3D in character_node.get_children():
		var potential_grid_position: int = a_star3d.get_closest_point(c.position)
		
		if point_list.has(potential_grid_position):
			point_list[potential_grid_position].character = c
			var world_pos: Vector3 = point_list[potential_grid_position].world_point
			c.position = world_pos
			c.current_position_key = potential_grid_position
			turn_controller.add_character(c)
		else:
			c.queue_free()
	turn_controller.set_up_turn_list()

func build_point_list() -> void:
	#var point_data: Array = a_star2d.get_point_data_in_region(grid_size)
	var id: int = 0
	for x in grid_size.size.x:
		for y in grid_size.size.y:
			var world_position = spawn_world_points(Vector2(x+grid_size.position.x,y+grid_size.position.y), id)
			if world_position[2]:
				point_list[id] =  {"grid_point":Vector2(x,y),
									"world_point": world_position[0],
									"indicator": world_position[1],
									"character" : null}
				id += 1


func spawn_world_points(_position: Vector2, id: int) -> Array:
	var new_world_point = WORLD_FINDER.instantiate()
	world_points.add_child(new_world_point)
	var valid_point: bool = true
	
	new_world_point.position = Vector3(_position.x+offset.x, 5, _position.y+offset.y)
	
	var height_data: Dictionary =  get_grid_height(new_world_point)
	
	if height_data:
		if height_data.collider.is_in_group("NonTraversable"):
			a_star3d.set_point_disabled(id)
			
		new_world_point.position = height_data.position
		new_world_point.set_show_debug(show_debug)
		
	else:
		new_world_point.queue_free()
		valid_point = false
		
	return [new_world_point.position,new_world_point,valid_point]

func get_grid_height(world_point) -> Dictionary:
	var _start_point: Vector3 = world_point.position
	var _end_point: Vector3 = world_point.position
	_end_point.y = -100
	var new_ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(_start_point, _end_point)
	new_ray_query.set_collision_mask(0b00001)
	var new_ray: Dictionary = get_world_3d().direct_space_state.intersect_ray(new_ray_query)
	return new_ray

func build_a_star_grid3d(points: Dictionary) -> void:
	for p in points:
		a_star3d.add_point(p,points[p].world_point)

func connect_points(points: Dictionary) -> void:
	for p in points:
		var connected: Array = get_connected_points(p)
		for c in connected:
			var neighbor_id : int = get_id_from_world_point(c)
			if points.has(neighbor_id):
				if not a_star3d.are_points_connected(p,neighbor_id):
					a_star3d.connect_points(p,neighbor_id)

func get_id_from_world_point(world_point: Vector3) -> int:
	var id: int = -1
	for p in point_list:
		if world_point.is_equal_approx(point_list[p].world_point):
			id = p
			break
	return id

func get_id_from_grid_point(grid_point: Vector2) -> int:
	var id: int = -1
	for p in point_list:
		var test_point: Vector2 = point_list[p].grid_point
		if grid_point.is_equal_approx(test_point):
			id = p
			break
	return id

func get_connected_points(id: int) -> Array:
	var grid_point: Vector2 = point_list[id].grid_point
	var world_point: Vector3 = point_list[id].world_point
	var connected: Array[Vector3]
	
	var adjacent_tiles : Array = [Vector2.UP,Vector2.LEFT, Vector2.DOWN, Vector2.RIGHT]
	
	for a in adjacent_tiles:
		var next_tile : Vector2 = (Vector2(grid_step_size.x,grid_step_size.z) * a)+grid_point
		var adt_id: int = get_id_from_grid_point(next_tile)
		if adt_id != -1:
			if test_height_difference(world_point,point_list[adt_id].world_point):
				connected.append(point_list[adt_id].world_point)
	return connected
	
func set_current_grid_id(id: int) -> void:
	if id == current_grid_id:
		return

	if point_list.has(id) and point_list.has(current_grid_id):
		if selected_attack_grid_id == -1 and selected_move_grid_id == -1:
			point_list[id].indicator.selected()
			point_list[current_grid_id].indicator.unselected()

	current_grid_id = id

func set_character_path(_id) -> Array:
	var path: PackedInt64Array = a_star3d.get_id_path(active_character.current_position_key,_id)
	var player_path: Array
	for p in path:
		player_path.push_back(point_list[p].world_point)

	point_list[active_character.current_position_key].character = null
	active_character.current_position_key = _id
	point_list[_id].character = active_character
	
	return player_path
	
func show_move_distance(_char: CharacterBody3D) -> void:
	var stats: CharacterStats = _char.character_stats
	var speed: int = stats.speed
	var current_position: int = active_character.current_position_key
	var potential_places: Array[Vector2]

	for x in speed:
		for y in speed-x:
			var north: Vector2 = Vector2(x,y)+point_list[current_position].grid_point
			var east: Vector2 = Vector2(x,-y)+point_list[current_position].grid_point
			var south: Vector2 = Vector2(-x,y)+point_list[current_position].grid_point
			var west: Vector2 = Vector2(-x,-y)+point_list[current_position].grid_point
			#
			if not potential_places.has(north):
				potential_places.append(north)
			if not potential_places.has(east):
				potential_places.append(east)
			if not potential_places.has(south):
				potential_places.append(south)
			if not potential_places.has(west):
				potential_places.append(west)

	for p in point_list:
		if potential_places.has(point_list[p].grid_point) and !point_list[p].character:
			var path_id: PackedInt64Array = a_star3d.get_id_path(current_position,p)
			if path_id.size()<= speed:
				active_selection_move_list.append(p) 
				point_list[p].indicator.potential_position = point_list[p].grid_point
				point_list[p].indicator.show_selectable_grid()
				point_list[p].indicator.suggested_path_choice = true

func show_attack_distance(_char: CharacterBody3D) -> void:
	var stats: CharacterStats = _char.character_stats
	var _range: int = stats.attack_range
	var current_position: int = active_character.current_position_key
	var potential_places: Array[Vector2]

	for x in _range:
		for y in _range-x:
			var north: Vector2 = Vector2(x,y)+point_list[current_position].grid_point
			var east: Vector2 = Vector2(x,-y)+point_list[current_position].grid_point
			var south: Vector2 = Vector2(-x,y)+point_list[current_position].grid_point
			var west: Vector2 = Vector2(-x,-y)+point_list[current_position].grid_point
			#
			if not potential_places.has(north):
				potential_places.append(north)
			if not potential_places.has(east):
				potential_places.append(east)
			if not potential_places.has(south):
				potential_places.append(south)
			if not potential_places.has(west):
				potential_places.append(west)
				
	for p in point_list:
		if potential_places.has(point_list[p].grid_point):
			active_selection_attack_list.append(p) 
			point_list[p].indicator.potential_position = point_list[p].grid_point
			point_list[p].indicator.show_attack_grid()
			point_list[p].indicator.suggested_attack_choice = true
			
func visualise_path(from: int, to: int) -> void:
	path_3d.curve.clear_points()
	var path = a_star3d.get_id_path(from, to)
	for p in path:
		var point = point_list[p].world_point
		path_3d.curve.add_point(point)

func test_height_difference(point: Vector3, potential_point: Vector3) -> bool:
	var valid_point: bool = false
	var height_difference: float = abs(point.y - potential_point.y)
	if height_difference < grid_step_size.y:
		valid_point = true
	return valid_point

func _on_turn_controller_move_request(character: Character) -> void:
	if selected_move_grid_id != -1:
		var player_path = set_character_path(selected_move_grid_id)
		turn_controller.move_accepted(player_path,point_list,a_star3d)
		clear_move_options()
		clear_attack_options()
	else:
		clear_move_options()
		clear_attack_options()
		show_move_distance(character)
		
func _on_turn_controller_active_character_changed(character: Character) -> void:
	clear_move_options()
	clear_attack_options()
	active_character = character

func clear_move_options() -> void:
	path_3d.curve.clear_points()
	
	for i in active_selection_move_list:
		point_list[i].indicator.suggested_path_choice = false
		point_list[i].indicator.unselected()
		
	selected_move_grid_id = -1
	active_selection_move_list.clear()

func clear_attack_options() -> void:
	for i in active_selection_attack_list:
		point_list[i].indicator.suggested_attack_choice = false
		point_list[i].indicator.unselected()
		
	selected_attack_grid_id = -1
	active_selection_attack_list.clear()

func _on_turn_controller_attack_request(character: Character) -> void:
	if selected_attack_grid_id != -1:
		var attacked_character: Character = get_grid_character(selected_attack_grid_id)
		if attacked_character:
			turn_controller.attack_accepted(attacked_character,point_list,a_star3d)
		clear_attack_options()
	else:
		clear_move_options()
		clear_attack_options()
		show_attack_distance(character)

func get_grid_character(id: int) -> Character:
	var obj: Character = point_list[id].character
	return obj
	
func _on_turn_controller_request_grid_info() -> void:
	turn_controller.recieve_grid_data(point_list, a_star3d)

func _on_ai_controller_move_id_select(ai: AiController, id: int) -> void:
	select_grid_id_for_move(id)
	await get_tree().create_timer(1.0).timeout
	ai.move_id_selected()

func _on_ai_controller_attack_id_select(ai: AiController, id: int)-> void:
	select_grid_id_for_attack(id)
	await get_tree().create_timer(1.0).timeout
	ai.attack_id_selected()
