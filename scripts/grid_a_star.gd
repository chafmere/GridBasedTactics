extends AStar3D
class_name AStarGrid3D

func _compute_cost(u, v):
	var u_pos = get_point_position(u)
	var v_pos = get_point_position(v)

	var result = abs(u_pos.x - v_pos.x)  + abs(u_pos.z - v_pos.z)
	if u_pos.x == v_pos.x:
		result -= .5

	return result
#
func _estimate_cost(u, v):
	var u_pos = get_point_position(u)
	var v_pos = get_point_position(v)

	var result = abs(u_pos.x - v_pos.x) + abs(u_pos.z - v_pos.z)
	if u_pos.x == v_pos.x:
		result -=  .5

	return result
