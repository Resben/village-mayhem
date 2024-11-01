extends Node2D

var data : DockData

func get_boat_position():
	return Global.main_map.map_to_local(data.connected_ocean_pos)

func get_land_position():
	return Global.main_map.map_to_local(data.connected_island_pos)
