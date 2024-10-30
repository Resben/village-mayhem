extends TileMap

enum {GRASS, SEA, HIGH}

@export var display_map : TileMap
@export var village_map : TileMap
@export var grass_placeholder_atlas : Vector2i
@export var high_placeholder_atlas : Vector2i
@export var sea_placeholder_atlas : Vector2i

@export var should_generate = true

var neighbours = [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]

var noise = FastNoiseLite.new()
var sea_threshold = 0.5
var high_threshold = 0.7
var minimum_island_size = 25

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
	display_map.clear()
	if should_generate:
		thread.start(thread_job_1)
	else:
		main_thread_setup()

#################################################################
###################### THREAD UNSAFE STUFF ######################
#################################################################

func main_thread_setup():
	for vec in get_used_cells(0):
		set_display_tile(vec)

func set_display_tile(vec):
	for i in neighbours.size():
		var new_pos = vec + neighbours[i]
		var displaySet = calculate_display_tile_temp(new_pos)
		display_map.set_cell(0, new_pos, displaySet[1], displaySet[0])

func calculate_display_tile_temp(vec):
	var atlas = []
	atlas.push_back(get_world_tile_existing(vec - neighbours[3]))
	atlas.push_back(get_world_tile_existing(vec - neighbours[2]))
	atlas.push_back(get_world_tile_existing(vec - neighbours[1]))
	atlas.push_back(get_world_tile_existing(vec - neighbours[0]))
	
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

func get_world_tile_existing(vec):
	var atlas = get_cell_atlas_coords(0, vec)
	if atlas == grass_placeholder_atlas:
		return GRASS
	elif atlas == high_placeholder_atlas:
		return HIGH
	else:
		return SEA

#################################################################
###################### THREAD SAFE STUFF ########################
#################################################################

var display_generated_map = []
var island_map = []
var docks = {}
var island_sizes = {}

var thread : Thread = Thread.new()
var is_setup = false

func thread_job_1():
	var generated_map = []
	
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.01
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	noise.seed = randi()
		
	initialise_map(generated_map)
	initialise_map(display_generated_map)
	initialise_island_map(island_map)
	generate_tilemap_from_noise(generated_map)
	
	for x in range(Global.map_size.x):
		for y in range(Global.map_size.y):
			generate_display_tile(generated_map, Vector2i(x, y))
	
	identify_islands()
	remove_docks()
	
	call_deferred("thread_complete")

func thread_complete():
	if thread.is_alive():
		thread.wait_to_finish()
	
	for x in range(Global.map_size.x):
		for y in range(Global.map_size.y):
			var displaySet = display_generated_map[x][y]
			display_map.set_cell(0, Vector2i(x, y), displaySet[1], displaySet[0])
	
	village_map.on_display_setup()
	village_map.generate_docks(docks)
	is_setup = true

################### GENERATE MAP ######################

func initialise_map(map):
	map.resize(Global.map_size.x)
	for x in range(Global.map_size.x):
		map[x] = Array()
		map[x].resize(Global.map_size.y)

func generate_tilemap_from_noise(map):
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
				
			map[x][y] = tile_id

func calculate_falloff(x, y, map_size):
	var distance_from_center = Vector2(x, y).distance_to(map_size / 2)
	var max_distance = sqrt(pow(map_size.x / 2, 2))
	var threshold_distance = max_distance * 0.8
	var normalised_distance = (distance_from_center - threshold_distance) / (max_distance - threshold_distance)
	return clamp(1.0 - normalised_distance, 0, 1)

################ MAP TO TILESET #################

func generate_display_tile(map, vec):
	for i in neighbours.size():
		var new_pos = vec + neighbours[i]
		var displaySet = calculate_display_tile(map, new_pos)
		if new_pos.x >= 0 and new_pos.x < Global.map_size.x and new_pos.y >= 0 and new_pos.y < Global.map_size.y:
			display_generated_map[new_pos.x][new_pos.y] = displaySet

func calculate_display_tile(map, vec):
	var atlas = []
	atlas.push_back(get_world_tile_from_generated(map, vec - neighbours[3]))
	atlas.push_back(get_world_tile_from_generated(map, vec - neighbours[2]))
	atlas.push_back(get_world_tile_from_generated(map, vec - neighbours[1]))
	atlas.push_back(get_world_tile_from_generated(map, vec - neighbours[0]))
	
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

func get_world_tile_from_generated(map, vec):
	var atlas
	if vec.x >= 0 and vec.x < Global.map_size.x and vec.y >= 0 and vec.y < Global.map_size.y:
		atlas = map[vec.x][vec.y]
	if atlas == grass_placeholder_atlas:
		return GRASS
	elif atlas == high_placeholder_atlas:
		return HIGH
	else:
		return SEA

################ DOCK GENERATION ################

func initialise_island_map(map):
	map.resize(Global.map_size.x)
	for x in range(Global.map_size.x):
		map[x] = []
		for y in range(Global.map_size.y):
			map[x].append(-1)

func get_island_id(raw_position) -> int:
	var vec = local_to_map(raw_position)
	if vec.x >= 0 and vec.x < Global.map_size.x and vec.y >= 0 and vec.y < Global.map_size.y:
		return island_map[vec.x][vec.y]
	else:
		return -1  # Return -1 if position is out of bounds or sea

func get_island_size(id):
	if id == -1:
		return 0
	return island_sizes[id]

func identify_islands():
	var island_id = 0
	for x in range(Global.map_size.x):
		for y in range(Global.map_size.y):
			if is_land_tile(x, y) and island_map[x][y] == -1:
				flood_fill_island(x, y, island_id)
				island_id += 1

func is_land_tile(x, y):
	var atlas = display_generated_map[x][y][0]
	var source = display_generated_map[x][y][1]
	if atlas != Vector2i(0, 3) && source == 1:
		return true
	elif source != 1:
		return true
	else:
		return false

func is_shore_tile(x, y):
	var atlas = display_generated_map[x][y][0]
	var source = display_generated_map[x][y][1]
	if atlas != Vector2i(0, 3) && atlas != Vector2i(2, 1) && source != 2:
		return true
	else:
		return false

func flood_fill_island(start_x, start_y, island_id):
	var stack = []
	stack.append(Vector2(start_x, start_y))
	var shoreline_tiles = []
	var island_size = 0

	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = int(current.x)
		var cy = int(current.y)

		# Skip if already visited
		if island_map[cx][cy] != -1:
			continue

		# Mark the tile with the island ID
		island_map[cx][cy] = island_id
		island_size += 1

		# Check neighbors for shorelines and connected land tiles
		for offset in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
			var nx = cx + int(offset.x)
			var ny = cy + int(offset.y)
			if nx >= 0 and nx < Global.map_size.x and ny >= 0 and ny < Global.map_size.y:
				if is_land_tile(nx, ny) and island_map[nx][ny] == -1:
					stack.append(Vector2(nx, ny))
					if is_shore_tile(nx, ny):
						shoreline_tiles.append(Vector2(cx, cy))  # Current tile is on shore
	
	island_sizes[island_id] = island_size
	
	# Place a dock on a random shoreline tile for this island
	if shoreline_tiles.size() > 0:
		docks[island_id] = shoreline_tiles[randi() % shoreline_tiles.size()]

func remove_docks():
	var docks_to_erase = []
	for d in docks:
		if island_sizes[d] < minimum_island_size:
			docks_to_erase.push_back(d)
	
	for e in docks_to_erase:
		docks.erase(e)
