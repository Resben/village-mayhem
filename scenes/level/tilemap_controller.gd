extends TileMap

enum {GRASS, SEA, HIGH}

@export var display_map : TileMap
@export var grass_placeholder_atlas : Vector2i
@export var high_placeholder_atlas : Vector2i
@export var sea_placeholder_atlas : Vector2i

@export var should_generate = true

var neighbours = [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]

var noise = FastNoiseLite.new()
var sea_threshold = 0.5
var high_threshold = 0.7

var neighbours_to_atlas_grass_sea = {
	## GRASS TO SEA
	[GRASS, GRASS, GRASS, GRASS] : Vector2i(2, 1),
	[SEA, SEA, SEA, GRASS] : Vector2i(1, 3),
	[SEA, SEA, GRASS, SEA] : Vector2i(0, 0),
	[SEA, GRASS, SEA, SEA] : Vector2i(0, 2),
	[GRASS, SEA, SEA, SEA] : Vector2i(3, 3),
	[SEA, GRASS, SEA, GRASS] : Vector2i(1, 0),
	[GRASS, SEA, GRASS, SEA] : Vector2i(3, 2),
	[SEA, SEA, GRASS, GRASS] : Vector2i(3, 0),
	[GRASS, GRASS, SEA, SEA] : Vector2i(1, 2),
	[SEA, GRASS, GRASS, GRASS] : Vector2i(1, 1),
	[GRASS, SEA, GRASS, GRASS] : Vector2i(2, 0),
	[GRASS, GRASS, SEA, GRASS] : Vector2i(2, 2),
	[GRASS, GRASS, GRASS, SEA] : Vector2i(3, 1),
	[SEA, GRASS, GRASS, SEA] : Vector2i(2, 3),
	[GRASS, SEA, SEA, GRASS] : Vector2i(0, 1),
	[SEA, SEA, SEA, SEA] : Vector2i(0, 3),
}

var neighbours_to_atlas_grass_highland = {
	## GRASS TO HIGHLAND
	[HIGH, HIGH, HIGH, HIGH] : Vector2i(2, 1),
	[GRASS, GRASS, GRASS, HIGH] : Vector2i(1, 3),
	[GRASS, GRASS, HIGH, GRASS] : Vector2i(0, 0),
	[GRASS, HIGH, GRASS, GRASS] : Vector2i(0, 2),
	[HIGH, GRASS, GRASS, GRASS] : Vector2i(3, 3),
	[GRASS, HIGH, GRASS, HIGH] : Vector2i(1, 0),
	[HIGH, GRASS, HIGH, GRASS] : Vector2i(3, 2),
	[GRASS, GRASS, HIGH, HIGH] : Vector2i(3, 0),
	[HIGH, HIGH, GRASS, GRASS] : Vector2i(1, 2),
	[GRASS, HIGH, HIGH, HIGH] : Vector2i(1, 1),
	[HIGH, GRASS, HIGH, HIGH] : Vector2i(2, 0),
	[HIGH, HIGH, GRASS, HIGH] : Vector2i(2, 2),
	[HIGH, HIGH, HIGH, GRASS] : Vector2i(3, 1),
	[GRASS, HIGH, HIGH, GRASS] : Vector2i(2, 3),
	[HIGH, GRASS, GRASS, HIGH] : Vector2i(0, 1),
	[GRASS, GRASS, GRASS, GRASS] : Vector2i(0, 3),
}

# Called when the node enters the scene tree for the first time.
func _ready():
	if should_generate:
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		noise.frequency = 0.01
		noise.fractal_octaves = 5
		noise.fractal_lacunarity = 2.0
		noise.fractal_gain = 0.5
		noise.seed = randi()
		display_map.clear()
		
		generate_tilemap_from_noise()
	
	for vec in get_used_cells(0):
		set_display_tile(vec)

func generate_tilemap_from_noise():
	for x in range(Global.map_size.x):
		for y in range(Global.map_size.y):
			var noise_value = clamp((noise.get_noise_2d(x, y) + 1) / 2, 0, 1)
			var edge_falloff = calculate_falloff(x, y, Global.map_size)
			noise_value *= edge_falloff
			var tile_id
			if noise_value > high_threshold:
				tile_id = Vector2i(2, 0)
			elif noise_value > sea_threshold:
				tile_id = Vector2i(0, 0)
			else:
				tile_id = Vector2i(1, 0)
				
			set_cell(0, Vector2i(x, y), 0, tile_id)

func calculate_falloff(x, y, map_size):
	var distance_from_center = Vector2(x, y).distance_to(map_size / 2)
	var max_distance = sqrt(pow(map_size.x / 2, 2))
	var threshold_distance = max_distance * 0.8
	var normalised_distance = (distance_from_center - threshold_distance) / (max_distance - threshold_distance)
	return clamp(1.0 - normalised_distance, 0, 1)

func set_display_tile(vec):
	for i in neighbours.size():
		var new_pos = vec + neighbours[i]
		var displaySet = calculate_display_tile(new_pos)
		display_map.set_cell(0, new_pos, displaySet[1], displaySet[0])

func calculate_display_tile(vec):
	var atlas = []
	atlas.push_back(get_world_tile(vec - neighbours[3]))
	atlas.push_back(get_world_tile(vec - neighbours[2]))
	atlas.push_back(get_world_tile(vec - neighbours[1]))
	atlas.push_back(get_world_tile(vec - neighbours[0]))
	
	var tileset = 1
	# MAKE SURE THAT SEA AND HIGHLAND DONT CROSS OVER
	if SEA in atlas:
		if HIGH in atlas:
			print("HIGH and SEA in same gridplacement")
			for a in atlas:
				if a == HIGH:
					a = GRASS
	elif HIGH in atlas:
		tileset = 2
	
	if tileset == 1:
		return [neighbours_to_atlas_grass_sea[atlas], tileset]
	else:
		return [neighbours_to_atlas_grass_highland[atlas], tileset]

func get_world_tile(vec):
	var atlas = get_cell_atlas_coords(0, vec)
	if atlas == grass_placeholder_atlas:
		return GRASS
	elif atlas == high_placeholder_atlas:
		return HIGH
	else:
		return SEA
