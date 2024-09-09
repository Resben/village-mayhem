extends TileMap

@export var display_map : TileMap

var id_to_atlas = {
	"house" : Vector2i(0, 0),
	"crop" : Vector2i(1, 0),
	"mine" : Vector2i(0, 1),
	"tree" : Vector2i(1, 1)
}

var atlas_to_id = {
	Vector2i(0, 0) : "house",
	Vector2i(1, 0) : "crop",
	Vector2i(0, 1) : "mine",
	Vector2i(1, 1) : "tree"
}

var id_to_scene = {
	"house" : preload("res://scenes/level/house.tscn"),
	"crop" : preload("res://scenes/level/house.tscn"),
	"mine" : preload("res://scenes/level/house.tscn"),
	"tree" : preload("res://scenes/level/house.tscn")
}

func _ready():
	for vec in get_used_cells(0):
		place_building(atlas_to_id[get_cell_atlas_coords(0, vec)], vec)

func place_building(id : String, pos : Vector2i):
	var local = map_to_local(pos)
	var scene = id_to_scene[id].instantiate()
	scene.position = local
	add_child(scene)

func check_availablity(raw_position) -> bool:
	var display_position = display_map.local_to_map(raw_position)
	var village_position = local_to_map(raw_position)
	var tile_source = get_cell_source_id(0, village_position)
	if tile_source == -1:
		var display_tile_sources = display_map.get_surrounding_cells(display_position)
		var point1 = display_tile_sources[0] + Vector2i(0, 1)
		var point2 = display_tile_sources[0] + Vector2i(0, -1)
		var point3 = display_tile_sources[2] + Vector2i(0, 1)
		var point4 = display_tile_sources[2] + Vector2i(0, -1)
		display_tile_sources.push_back(point1)
		display_tile_sources.push_back(point2)
		display_tile_sources.push_back(point3)
		display_tile_sources.push_back(point4)
		
		for source in display_tile_sources:
			if display_map.get_cell_atlas_coords(0, source) != Vector2i(2, 1):
				return false
	else:
		return false
	
	print("was true")
	return true
