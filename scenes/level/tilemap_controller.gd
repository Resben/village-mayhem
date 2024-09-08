extends TileMap

enum {GRASS, DIRT}

@export var display_map : TileMap
@export var grass_placeholder_atlas : Vector2i
@export var dirt_placeholder_atlas : Vector2i

var neighbours = [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]

var neighbours_to_atlas = {
	[GRASS, GRASS, GRASS, GRASS] : Vector2i(2, 1),
	[DIRT, DIRT, DIRT, GRASS] : Vector2i(1, 3),
	[DIRT, DIRT, GRASS, DIRT] : Vector2i(0, 0),
	[DIRT, GRASS, DIRT, DIRT] : Vector2i(0, 2),
	[GRASS, DIRT, DIRT, DIRT] : Vector2i(3, 3),
	[DIRT, GRASS, DIRT, GRASS] : Vector2i(1, 0),
	[GRASS, DIRT, GRASS, DIRT] : Vector2i(3, 2),
	[DIRT, DIRT, GRASS, GRASS] : Vector2i(3, 0),
	[GRASS, GRASS, DIRT, DIRT] : Vector2i(1, 2),
	[DIRT, GRASS, GRASS, GRASS] : Vector2i(1, 1),
	[GRASS, DIRT, GRASS, GRASS] : Vector2i(2, 0),
	[GRASS, GRASS, DIRT, GRASS] : Vector2i(2, 2),
	[GRASS, GRASS, GRASS, DIRT] : Vector2i(3, 1),
	[DIRT, GRASS, GRASS, DIRT] : Vector2i(2, 3),
	[GRASS, DIRT, DIRT, GRASS] : Vector2i(0, 1),
	[DIRT, DIRT, DIRT, DIRT] : Vector2i(0, 3),
}

# Called when the node enters the scene tree for the first time.
func _ready():
	for vec in get_used_cells(0):
		set_display_tile(vec)

func set_display_tile(vec):
	for i in neighbours.size():
		var new_pos = vec + neighbours[i]
		display_map.set_cell(0, new_pos, 1, calculate_display_tile(new_pos))

func calculate_display_tile(vec):
	var bottom_right = get_world_tile(vec - neighbours[0])
	var bottom_left = get_world_tile(vec - neighbours[1])
	var top_right = get_world_tile(vec - neighbours[2])
	var top_left = get_world_tile(vec - neighbours[3])
	
	return neighbours_to_atlas[[top_left, top_right, bottom_left, bottom_right]]

func get_world_tile(vec):
	var atlas = get_cell_atlas_coords(0, vec)
	if atlas == grass_placeholder_atlas:
		return GRASS
	else:
		return DIRT
