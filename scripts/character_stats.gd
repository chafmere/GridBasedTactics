extends Resource
class_name CharacterStats

@export var name: String

@export var speed: int = 2
@export var attack: float
@export var defence: float
@export var agility: float

@export_range(2,20,1) var attack_range: int
