extends Node
class_name Health

signal character_death
signal health_remaining(health_percentage: float)

enum HealthState{ALIVE, DEAD}
var health_state: HealthState = HealthState.ALIVE

@export var max_health: float = 100
var health: float

func _ready() -> void:
	health = max_health
	check_health() 
	
func take_damage(dmg: float) -> void:
	health -= dmg
	check_health()
	
func check_health() -> void:
	if health <= 0:
		character_death.emit()
		health_state = HealthState.DEAD
	var health_percentage = health/max_health
	health_remaining.emit(health_percentage)
