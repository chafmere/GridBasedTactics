extends Node
class_name AiController

signal iniate_move
signal iniate_attack
signal move_id_select(ai: AiController, id: int)
signal attack_id_select(ai: AiController, id: int)
signal end_turn

var potential_attack_characters: Array[Character]
var potential_move_characters: Array[Character]

func _receive_player_info(character: Character, grid: Dictionary, a_star: AStarGrid3D, moves: Array[TurnController.ActionList]) -> void:
	potential_attack_characters.clear()
	potential_move_characters.clear()

	determine_action(character,grid, a_star, moves)


func determine_action(character: Character, grid: Dictionary, a_star: AStarGrid3D, moves: Array[TurnController.ActionList]) -> void:
	var targets: Array[Character] = _find_targets(grid,character)
	targets.sort_custom(sort_attack_priority)

	if moves.has(TurnController.ActionList.ATTACK):
		var attack_possible: bool = check_for_players_in_attack_range(character, grid)
		if attack_possible:
			attack_request_process()
			return
			
	if moves.has(TurnController.ActionList.MOVE):
		if not targets.is_empty():
			move_request_process(character,grid,a_star,targets)
			return
			
	await get_tree().create_timer(.2).timeout
	end_turn.emit()

func attack_request_process() -> void:
	iniate_attack.emit()
	await get_tree().create_timer(.2).timeout
	var attack_id = potential_attack_characters[0].current_position_key
	attack_id_select.emit(self, attack_id)

func attack_id_selected() -> void:
	iniate_attack.emit()
	
func move_request_process(character: Character, grid: Dictionary, a_star: AStarGrid3D, targets:Array[Character]) -> void:
	iniate_move.emit()
	await get_tree().create_timer(.2).timeout
	var end_id = _closest_point_to_target(character, targets[0].current_position_key,a_star,grid)
	move_id_select.emit(self,end_id)

func move_id_selected() -> void:
	iniate_move.emit()

func _closest_point_to_target(_char: Character, target_id: int, a_star: AStarGrid3D, grid: Dictionary) -> int:
	var end_id: int = _char.current_position_key
	var move_list: Array[int] = get_move_points(_char,_char.character_stats.speed,grid)
	
	var point_connections: PackedInt64Array = a_star.get_point_connections(target_id)
	
	for p in point_connections:
		if move_list.has(p):
			end_id = p
			return end_id
	
	var path = a_star.get_id_path(_char.current_position_key,point_connections[0])
	path = path.slice(0,_char.character_stats.speed)
	
	for p in path:
		if move_list.has(p):
			end_id = p
			
	return end_id
	
func _find_targets(grid: Dictionary, character: Character) -> Array:
	var targets: Array[Character]
	for i in grid:
		var _char : Character = grid[i].character
		if _char:
			if _char.character_team != character.character_team and _char.health_container.health_state == Health.HealthState.ALIVE:
				targets.append(_char)
				
	return targets

func check_for_players_in_attack_range(character: Character, grid: Dictionary)-> bool:
	var attack_points: Array = get_attack_points(character,character.character_stats.attack_range, grid)
	for i in attack_points:
		var _char : Character = grid[i].character
		if _char:
			if _char.character_team != character.character_team and _char.health_container.health_state == Health.HealthState.ALIVE:
				potential_attack_characters.append(_char)
				
	if not potential_attack_characters.is_empty():
		potential_attack_characters.sort_custom(sort_attack_priority)
		return true
	return false

func get_move_points(character: Character,_range: int ,grid: Dictionary) -> Array:
	var current_position: int = character.current_position_key
	var potential_places: Array[Vector2]
	var grid_list: Array[int]
	
	for x in _range:
		for y in _range-x:
			var north: Vector2 = Vector2(x,y)+grid[current_position].grid_point
			var east: Vector2 = Vector2(x,-y)+grid[current_position].grid_point
			var south: Vector2 = Vector2(-x,y)+grid[current_position].grid_point
			var west: Vector2 = Vector2(-x,-y)+grid[current_position].grid_point
			#
			if not potential_places.has(north):
				potential_places.append(north)
			if not potential_places.has(east):
				potential_places.append(east)
			if not potential_places.has(south):
				potential_places.append(south)
			if not potential_places.has(west):
				potential_places.append(west)
				
	for p in grid:
		if potential_places.has(grid[p].grid_point) and !grid[p].character:
			grid_list.append(p) 
			
	return grid_list
	
func get_attack_points(character: Character,_range: int ,grid: Dictionary) -> Array:
	var current_position: int = character.current_position_key
	var potential_places: Array[Vector2]
	var grid_list: Array[int]
	
	for x in _range:
		for y in _range-x:
			var north: Vector2 = Vector2(x,y)+grid[current_position].grid_point
			var east: Vector2 = Vector2(x,-y)+grid[current_position].grid_point
			var south: Vector2 = Vector2(-x,y)+grid[current_position].grid_point
			var west: Vector2 = Vector2(-x,-y)+grid[current_position].grid_point
			#
			if not potential_places.has(north):
				potential_places.append(north)
			if not potential_places.has(east):
				potential_places.append(east)
			if not potential_places.has(south):
				potential_places.append(south)
			if not potential_places.has(west):
				potential_places.append(west)
				
	for p in grid:
		if potential_places.has(grid[p].grid_point):
			grid_list.append(p) 
			
	return grid_list
	
func sort_attack_priority(a: Character, b: Character) -> bool:
	var a_health: float = a.health_container.health
	var b_health: float = b.health_container.health

	if a_health > b_health:
		return true
	return false
	
