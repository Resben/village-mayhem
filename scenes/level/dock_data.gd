extends Resource
class_name DockData

var map_position : Vector2i
var connected_ocean_id : int
var connected_ocean_pos : Vector2i
var connected_island_id : int
var connected_island_pos : Vector2i

func is_set() -> bool:
	if map_position != null && connected_ocean_id != null && connected_island_id != null:
		return true
	return false
