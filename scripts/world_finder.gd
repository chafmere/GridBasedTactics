extends Marker3D

@onready var decal: Decal = $Decal
@onready var debug_label: Label3D = $DebugLabel

@export var selected_material: Texture2D
@export var blue_material: Texture2D
@export var empty_material: Texture2D
@export var selected_blue: Texture2D
@export var debug_tex: Texture2D
@export var attack_area: Texture2D
@export var attack_area_selected: Texture2D

@export var show_debug: bool = false
var suggested_path_choice: bool = false
var suggested_attack_choice: bool = false
var potential_position: Vector2i = Vector2i.ZERO

func _ready() -> void:
	debug_label.hide()
	decal.texture_albedo = empty_material
	if show_debug:
		decal.texture_albedo = debug_tex


func selected()-> void:
	if suggested_path_choice:
		decal.texture_albedo = selected_blue
	elif suggested_attack_choice:
		decal.texture_albedo = attack_area_selected
	else:
		decal.texture_albedo = selected_material
	
func unselected() -> void:
	if suggested_path_choice:
		show_selectable_grid()
	elif suggested_attack_choice:
		show_attack_grid()
	else:
		decal.texture_albedo = empty_material
		if show_debug:
			decal.texture_albedo = debug_tex
		debug_label.hide()

func show_selectable_grid() -> void:
	decal.texture_albedo = blue_material
	if show_debug:
		debug_label.show()
		debug_label.text = str(potential_position.x)+" , "+str(potential_position.y)

func set_show_debug(_show_debug: bool) -> void:
	show_debug = _show_debug
	if _show_debug:
		decal.texture_albedo = debug_tex
	else:
		decal.texture_albedo = empty_material

func show_attack_grid() -> void:
	decal.texture_albedo = attack_area
	if show_debug:
		debug_label.show()
		debug_label.text = str(potential_position.x)+" , "+str(potential_position.y)
