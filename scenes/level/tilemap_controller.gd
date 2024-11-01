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

var display_generated_map = [] # Generated map based on noise texture
var island_map = [] # Land map position to island id
var ocean_map = [] # Ocean map position to ocean id
var docks = {} # List of docks
var island_sizes = {} # Island id to island size
var ocean_sizes = {} # Ocean id to ocean size
var shoreline_tiles = {} # Ocean id to array of island ids to array of shoreline positions

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
	initialise_flood_map(island_map)
	initialise_flood_map(ocean_map)
	generate_tilemap_from_noise(generated_map)
	
	for x in range(Global.map_size.x):
		for y in range(Global.map_size.y):
			generate_display_tile(generated_map, Vector2i(x, y))
	
	identify_oceans()
	identify_islands()
	identify_shorelines()
	generate_docks()
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
	Global.main_map = self
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

func initialise_flood_map(map):
	map.resize(Global.map_size.x)
	for x in range(Global.map_size.x):
		map[x] = []
		for y in range(Global.map_size.y):
			map[x].append(-1)

func get_island_id(raw_position) -> int:
	var vec = display_map.local_to_map(raw_position)
	if vec.x >= 0 and vec.x < Global.map_size.x and vec.y >= 0 and vec.y < Global.map_size.y:
		return island_map[vec.x][vec.y]
	else:
		return -1  # Return -1 if position is out of bounds or sea

func get_ocean_id(raw_position) -> int:
	var vec = display_map.local_to_map(raw_position)
	if vec.x >= 0 and vec.x < Global.map_size.x and vec.y >= 0 and vec.y < Global.map_size.y:
		return ocean_map[vec.x][vec.y]
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

func identify_oceans():
	var ocean_id = 0
	for x in range(Global.map_size.x):
		for y in range(Global.map_size.y):
			if is_ocean_tile(x, y) and ocean_map[x][y] == -1:
				flood_fill_ocean(x, y, ocean_id)
				ocean_id += 1

func identify_shorelines():
	for x in range(Global.map_size.x):
		for y in range(Global.map_size.y):
			if is_ocean_tile(x, y) and !visited.has(Vector2i(x, y)):
				var ocean_id = get_ocean_id(display_map.map_to_local(Vector2i(x, y)))
				flood_fill_shorelines(x, y, ocean_id)

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

func is_ocean_tile(x, y):
	var atlas = display_generated_map[x][y][0]
	var source = display_generated_map[x][y][1]
	if atlas == Vector2i(0, 3) && source == 1:
		return true
	else:
		return false

func flood_fill_ocean(start_x, start_y, ocean_id):
	var stack = []
	stack.append(Vector2i(start_x, start_y))
	var ocean_size = 0

	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = int(current.x)
		var cy = int(current.y)

		# Skip if already visited
		if ocean_map[cx][cy] != -1:
			continue

		# Mark the tile with the ocean ID
		ocean_map[cx][cy] = ocean_id
		ocean_size += 1

		# Check neighbors to continue the fill
		for offset in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = cx + int(offset.x)
			var ny = cy + int(offset.y)
			if nx >= 0 and nx < Global.map_size.x and ny >= 0 and ny < Global.map_size.y:
				if is_ocean_tile(nx, ny) and ocean_map[nx][ny] == -1:
					stack.append(Vector2i(nx, ny))
		
	ocean_sizes[ocean_id] = ocean_size

func flood_fill_island(start_x, start_y, island_id):
	var stack = []
	stack.append(Vector2i(start_x, start_y))
	var island_size = 0
	var next_shoreline = []

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
		for offset in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = cx + int(offset.x)
			var ny = cy + int(offset.y)
			if nx >= 0 and nx < Global.map_size.x and ny >= 0 and ny < Global.map_size.y:
				if is_land_tile(nx, ny) and island_map[nx][ny] == -1:
					stack.append(Vector2i(nx, ny))
	
	island_sizes[island_id] = island_size

var visited = {}  # Keep track of visited tiles in this flood fill

# Flood-fill function to identify shorelines for a given ocean tile
func flood_fill_shorelines(start_x, start_y, ocean_id):
	var stack = []
	stack.append(Vector2i(start_x, start_y))
	
	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = int(current.x)
		var cy = int(current.y)
		
		# Skip if already visited
		if visited.has(Vector2i(cx, cy)):
			continue
		
		visited[Vector2i(cx, cy)] = true
		
		# Check neighbors
		for offset in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var nx = cx + int(offset.x)
			var ny = cy + int(offset.y)
			
			if nx >= 0 and nx < Global.map_size.x and ny >= 0 and ny < Global.map_size.y:
				if is_land_tile(nx, ny):
					# This tile is a shoreline
					var island_id = get_island_id(display_map.map_to_local(Vector2i(nx, ny)))
					
					# Add to shoreline_tiles under the correct ocean_id and island_id
					if not shoreline_tiles.has(ocean_id):
						shoreline_tiles[ocean_id] = {}
					
					if not shoreline_tiles[ocean_id].has(island_id):
						shoreline_tiles[ocean_id][island_id] = []

					# Record the shoreline position
					shoreline_tiles[ocean_id][island_id].append(Vector2i(nx, ny))
				elif is_ocean_tile(nx, ny):
					# Continue flood filling into adjacent ocean tiles
					stack.append(Vector2i(nx, ny))

func generate_docks():
	var new_shoreline_tile_map = shoreline_tiles.duplicate(true)
	
	for ocean in shoreline_tiles:
		for island in shoreline_tiles[ocean]:
			if get_island_size(island) < minimum_island_size:
				new_shoreline_tile_map[ocean].erase(island)
	
	for ocean in new_shoreline_tile_map:
		if new_shoreline_tile_map[ocean].size() > 1:
			for island in new_shoreline_tile_map[ocean]:
				if !docks.has(island):
					docks[island] = {}
				if docks[island].has(ocean):
					print("Island cannot have multiple docks for the same ocean")
				var dockData = DockData.new()
				var random_tile = shoreline_tiles[ocean][island][randi() % shoreline_tiles[ocean][island].size()]
				dockData.map_position = random_tile
				dockData.connected_island_id = get_island_id(display_map.map_to_local(random_tile))
				dockData.connected_island_pos = random_tile
				for n in neighbours.size():
					var newPos = random_tile + neighbours[n]
					if newPos.x >= 0 and newPos.x < Global.map_size.x and newPos.y >= 0 and newPos.y < Global.map_size.y:
						if display_generated_map[newPos.x][newPos.y][0] == Vector2i(0, 3) && display_generated_map[newPos.x][newPos.y][1] == 1:
							dockData.connected_ocean_pos = newPos
							dockData.connected_ocean_id = get_ocean_id(newPos)
				if !dockData.is_set():
					print("Something went wrong")
				docks[island][ocean] = dockData
	print(docks)
