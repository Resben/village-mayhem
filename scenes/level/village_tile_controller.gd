extends TileMap

@export var display_map : TileMap

var id_to_atlas = {
	"house" : Vector2i(0, 0)
}

func place_building(id : String, pos : Vector2i):
	match id:
		"house":
			pass

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
