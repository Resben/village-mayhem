extends TileMap

@export var display_map : TileMap
@export var should_generate_random = true
@export var cam : Camera2D

var num_trees = 30
var num_mines = 10

var id_to_atlas = {
	"house" : Vector2i(0, 0),
	"crop" : Vector2i(1, 0),
	"mine" : Vector2i(0, 1),
	"tree" : Vector2i(1, 1),
	"town_hall" : Vector2i(0, 2)
}

var atlas_to_id = {
	Vector2i(0, 0) : "house",
	Vector2i(1, 0) : "crop",
	Vector2i(0, 1) : "mine",
	Vector2i(1, 1) : "tree",
	Vector2i(0, 2) : "town_hall"
}

var id_to_scene = {
	"house" : preload("res://scenes/level/house.tscn"),
	"crop" : preload("res://scenes/level/farm.tscn"),
	"mine" : preload("res://scenes/level/house.tscn"),
	"tree" : preload("res://scenes/level/wood_resource.tscn"),
	"town_hall" : preload("res://scenes/level/town_hall.tscn"),
	"dock" : preload("res://scenes/level/dock.tscn")
}

func _ready():
	pass

func on_display_setup():
	if should_generate_random:
		var flag = true
		var th_location
		var farm_location
		while flag:
			th_location = get_random_valid_display_position()
			for i in get_surrounding_cells(th_location):
				if check_availablity(map_to_local(i)):
					farm_location = i
					flag = false
					break
			
		place_building("town_hall", th_location, false)
		place_building("crop", farm_location, false)
		
		for i in range(num_trees):
			place_building("tree", get_random_valid_display_position(), false)
		
	else:
		for vec in get_used_cells(0):
			place_building(atlas_to_id[get_cell_atlas_coords(0, vec)], vec, false)
	
	cam.set_camera_position(map_to_local(get_used_cells_by_id(0, 0, Vector2i(0, 2))[0]))

func place_building(id : String, pos : Vector2i, should_construct : bool):
	var local = map_to_local(pos)
	var scene = id_to_scene[id].instantiate() as Workable
	scene.position = local
	if should_construct:
		scene.state = Workable.CONSTRUCTION
	else:
		scene.state = Workable.BUILT
	
	add_child(scene)
	set_cell(0, pos, 0, id_to_atlas[id])
	return scene

func get_random_valid_display_position():
	var flag = true
	var tiles = display_map.get_used_cells_by_id(0, 1, Vector2i(2, 1)) + display_map.get_used_cells_by_id(0, 2, Vector2i(2, 1))
	var rand
	while flag:
		rand = randi_range(0, tiles.size() - 1)
		if tiles.size() == 0:
			print("no more tiles")
			flag = false
			break
		if check_availablity(display_map.map_to_local(tiles[rand - 1])):
			flag = false
	
	if tiles.size() == 0:
		return null
	
	# Convert from display to village locations
	var village_map_location = local_to_map(display_map.map_to_local(tiles[rand - 1]))
	
	return village_map_location

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
	
	return true

func generate_docks(docks):
	var new_docks = {}
	for island in docks:
		for ocean in docks[island]:
			var scene = id_to_scene["dock"].instantiate()
			var new_position = display_map.map_to_local(docks[island][ocean].map_position)
			
			scene.position = new_position
			scene.data = docks[island][ocean]
			new_docks[Vector2i(island, ocean)] = scene
			add_child(scene)
	Global.docks = new_docks
