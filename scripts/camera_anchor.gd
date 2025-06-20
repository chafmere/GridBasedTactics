extends Node3D

var new_tween: Tween
var vert_tween: Tween
var character_tween: Tween

var starting_rotation: int = 45
var base_rotation : int = 50
var vertical_rotation: int = 45

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_left"):
		starting_rotation += 90
		if new_tween:
			new_tween.kill()
		new_tween = get_tree().create_tween()
		new_tween.tween_property(self,"rotation:y",deg_to_rad(starting_rotation),.5)
	if event.is_action_pressed("rotate_right"):
		starting_rotation -= 90
		if new_tween:
			new_tween.kill()
		new_tween = get_tree().create_tween()
		new_tween.tween_property(self,"rotation:y",deg_to_rad(starting_rotation),.5)
	
	if event.is_action_pressed("vertical_rotation"):
		if vert_tween:
			vert_tween.kill()
		
		new_tween = get_tree().create_tween()
		new_tween.tween_property(self,"rotation:x",0,.2)
		
	if event.is_action_released("vertical_rotation"):
		if vert_tween:
			vert_tween.kill()
		
		new_tween = get_tree().create_tween()
		new_tween.tween_property(self,"rotation:x",deg_to_rad(vertical_rotation),.2)

func focus_character(character: Character) -> void:
	var character_position: Vector3 = character.global_position
	
	if global_position.is_equal_approx(character_position):
		return
		
	if character_tween:
		character_tween.kill()
		
	character_tween = get_tree().create_tween()
	character_tween.tween_property(self, "global_position", character_position, .1)


func _on_world_character_selected(character: Character) -> void:
	focus_character(character)

func _on_turn_controller_active_character_changed(character: Character) -> void:
	focus_character(character)
