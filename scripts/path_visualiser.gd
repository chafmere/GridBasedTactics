extends Node3D

var mesh_verticies: int = 4
var mesh_array: Array

func _create_visual_path(path: Array[Vector3]) ->void:
	for p in path:
		var mesh = ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		mesh.surface_add_vertex(Vector3.LEFT)
		mesh.surface_add_vertex(Vector3.FORWARD)
		mesh.surface_add_vertex(Vector3.ZERO)
		mesh.surface_end()
		mesh.global_position = p
		add_child(mesh)
