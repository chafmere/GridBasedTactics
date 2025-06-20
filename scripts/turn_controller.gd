extends Node
class_name TurnController

enum ActionList{MOVE, ATTACK, FINISH}

signal active_character_changed(character: Character)
signal move_request(character: Character)
signal attack_request(character: Character)
signal request_grid_info()

@onready var ai_controller: Node = $AiController
@onready var player_input: VBoxContainer = %PlayerInput
@onready var move_button: Button = %MoveButton
@onready var attack_button: Button = %AttackButton
@onready var finish_button: Button = %FinishButton
@onready var victory: Control = $CanvasLayer/Victory
@onready var game_over: Control = $CanvasLayer/GameOver

var character_list: Array[Character]
var turn_order: Array
var active_character: Character
var turn_number: int = 0
var available_moves: Array[ActionList]
var team_list: Dictionary[Character.CharacterTeam,Array]

func add_character(_character: Character) -> void:
	character_list.append(_character)
	if team_list.has(_character.character_team):
		team_list[_character.character_team].append(_character)
	else:
		team_list[_character.character_team] = [_character]
	_character.health_container.character_death.connect(remove_character_on_death.bind(_character))

func remove_character_on_death(_char: Character) -> void:
	character_list.erase(_char)
	team_list[_char.character_team].erase(_char)
	check_tean_status()
	
func check_tean_status() -> void:
	var player_team: int = 0
	var enemy_team: int = 0
	
	for i in team_list.keys():
		if i == Character.CharacterTeam.PLAYER_TEAM:
			player_team = team_list[i].size()
		elif i == Character.CharacterTeam.ENEMY_TEAM:
			enemy_team = team_list[i].size()
			
	if player_team == 0:
		get_tree().paused = true
		game_over.show()
		
	elif enemy_team == 0:
		get_tree().paused = true
		victory.show()


func set_up_turn_list() -> void:
	character_list.sort_custom(sort_turn_order)
	turn_order.append_array(character_list)
	set_active_character()

func sort_turn_order(a: Character, b: Character) -> bool:
	var a_speed: float = (a.character_stats.speed + a.character_stats.agility)/2 
	var b_speed: float = (b.character_stats.speed + b.character_stats.agility)/2 

	if a_speed > b_speed:
		return true
	return false

func set_active_character() -> void:
	if not turn_order.is_empty():
		active_character = turn_order.pop_front()
		refresh_available_moves()
	else:
		set_up_turn_list() 
		
	active_character_changed.emit(active_character)
	_set_player_type(active_character)


func _set_player_type(_char: Character) -> void:
	player_input.hide()
	match _char.character_type:
		Character.CharcterType.PLAYER:
			player_input.show()
		Character.CharcterType.AI:
			request_grid_info.emit()
		Character.CharcterType.NETWORK:
			pass

func refresh_available_moves() -> void:
	available_moves = [ActionList.MOVE, ActionList.ATTACK, ActionList.FINISH]
	move_button.disabled = false
	attack_button.disabled = false
	
func move_used(action: ActionList) -> void:
	available_moves.erase(action)
	
func _on_finish_button_pressed() -> void:
	set_active_character()

func _on_move_button_pressed() -> void:
	if available_moves.has(ActionList.MOVE):
		move_request.emit(active_character)

func _on_attack_button_pressed() -> void:
	if available_moves.has(ActionList.ATTACK):
		attack_request.emit(active_character)
		
func move_accepted(path: Array, grid: Dictionary, a_star: AStarGrid3D) -> void:
	active_character.update_path(path)
	available_moves.erase(ActionList.MOVE)
	if active_character.character_type == Character.CharcterType.PLAYER:
		move_button.disabled = true
	elif active_character.character_type == Character.CharcterType.AI:
		await active_character.path_completed
		recieve_grid_data(grid, a_star)
	
func attack_accepted(_char_attacked: Character,grid: Dictionary, a_star: AStarGrid3D) -> void:
	var damage = calculate_damage(active_character.character_stats.attack, _char_attacked.character_stats.defence)
	calculate_hit(_char_attacked.character_stats.agility)
	_char_attacked.health_container.take_damage(damage)
	available_moves.erase(ActionList.ATTACK)
	
	if active_character.character_type == Character.CharcterType.PLAYER:
		attack_button.disabled = true
	elif active_character.character_type == Character.CharcterType.AI:
		recieve_grid_data(grid, a_star)
	
func calculate_damage(attack: float, defence: float) -> float:
	var damage: float = attack * (100/(defence+100))
	return damage

func calculate_hit(agi: float) -> bool:
	var hit: bool = true
	var hit_chance: float = (100/(agi+100))*100
	var rand_chance: float = randf_range(0,70)
	if rand_chance > hit_chance:
		hit = false
	return hit

func recieve_grid_data(grid: Dictionary, a_star: AStarGrid3D) -> void:
	if active_character.character_type == Character.CharcterType.AI:
		ai_controller._receive_player_info(active_character,grid, a_star,available_moves)

func _on_ai_controller_iniate_move() -> void:
	_on_move_button_pressed()

func _on_ai_controller_end_turn() -> void:
	set_active_character()

func _on_ai_controller_iniate_attack() -> void:
	_on_attack_button_pressed()
