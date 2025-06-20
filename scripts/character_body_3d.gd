extends CharacterBody3D
class_name Character

signal path_completed

enum CharcterType {PLAYER,AI,NETWORK}
enum CharacterTeam {PLAYER_TEAM,ENEMY_TEAM}

@export var character_stats: CharacterStats
@export var health_container: Health 
@export var character_type: CharcterType
@export var character_team: CharacterTeam
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPEED = 5.0

var current_position_key: int 
var path: Array
var current_target: Vector3 = Vector3.INF
var travel: bool = false
var path_desired_distance: float = 0.1

func _physics_process(_delta: float) -> void:
	if travel:
		if current_target != Vector3.INF:
			var dir: Vector3 = global_position.direction_to(current_target).normalized()
			velocity = dir * SPEED
			if global_position.distance_to(current_target) < path_desired_distance:
				get_next_point_in_path()
		else:
			velocity = Vector3.ZERO
			path_completed.emit()
			travel = false
		
		move_and_slide()

func get_next_point_in_path() -> void:
	if path.size() > 0:
		var new_target: Vector3 = path.pop_front()
		current_target = new_target
	else:
		current_target = Vector3.INF

func update_path(new_path: Array) -> void:
	path = new_path
	get_next_point_in_path()
	travel = true

func _on_health_character_death() -> void:
	animation_player.play("death")
