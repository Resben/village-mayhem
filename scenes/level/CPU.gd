extends Node2D
class_name CPU

@export var village_map : TileMap

func _ready():
	Global.cpu = self
	$ActionTimer.start()

func add_villager(villager : Villager):
	add_child(villager)
	Global.villager_references.push_back(villager)

func on_disaster():
	for v in Global.villager_references:
		v.on_disaster()

func disaster_over():
	for v in Global.villager_references:
		v.disaster_over()

#################################################################################
############################### VILLAGE PLACEMENT ###############################
#################################################################################

func construct_farm():
	var total_visited_locations = []
	var next_location
	var house_at_other
	for l in village_map.get_used_cells_by_id(0, 0, Vector2i(1, 0)):
		if !total_visited_locations.has(l):
			house_at_other = count_cluster(l, total_visited_locations, "house")
			if house_at_other < 4:
				next_location = get_next_location(l, "farm")
				if next_location != null:
					print("Found existing location for farm")
					break
	
	if next_location == null:
		next_location = village_map.get_random_valid_display_position()
		print("Created new random location for farm")
	
	if next_location != null:
		village_map.set_cell(0, next_location, 0, Vector2i(1, 0))
		return village_map.place_building("crop", next_location, false)
	else:
		return null

# Called by villager to create a new house then assign said villager as a builder
func construct_house():
	var total_visited_locations = []
	var th_location = village_map.get_used_cells_by_id(0, 0, Vector2i(0, 2))[0]
	var house_at_th = count_cluster(th_location, total_visited_locations, "house")
	print(str(house_at_th) + " num for townhall")
	var next_location
	var house_at_other
	if house_at_th >= 5:
		for l in village_map.get_used_cells_by_id(0, 0, Vector2i(0, 0)):
			if !total_visited_locations.has(l):
				house_at_other = count_cluster(l, total_visited_locations, "house")
				if house_at_other < 3:
					next_location = get_next_location(l, "house")
					if next_location != null:
						print("Used non TH location")
						break
	else:
		next_location = get_next_location(th_location, "house")
		print("Used TH location")
	
	if next_location == null:
		next_location = village_map.get_random_valid_display_position()
		print("Created new random location")
	
	if next_location != null:
		village_map.set_cell(0, next_location, 0, Vector2i(0, 0))
		return village_map.place_building("house", next_location, true)
	else:
		return null

# Gets a random object of a given id
func get_next_location(pos, id):
	var neighbours = get_neighbours(pos, id)
	var total_neighbours = []
	for n in neighbours:
		if !total_neighbours.has(n):
			total_neighbours.push_back(n)
		for n2 in get_neighbours(n, id):
			if !total_neighbours.has(n2):
				total_neighbours.push_back(n2)
	
	var next_location = null
	
	while next_location == null || total_neighbours.size() != 0:
		var next_neighbour = total_neighbours[randi_range(1, total_neighbours.size()) - 1]
		var empty_neigbours = get_neighbours(next_neighbour, "empty")
		if empty_neigbours.size() != 0:
			var next_empty = empty_neigbours[randi_range(1, empty_neigbours.size()) - 1]
			if village_map.check_availablity(village_map.map_to_local(next_empty)):
				next_location = next_empty
		total_neighbours.erase(next_neighbour)
	
	return next_location

func count_cluster(pos, total_visited, type):
	var visited_positions = {}
	var queue = [pos]
	var house_count = 0
	
	if !check_type(village_map.get_cell_atlas_coords(0, pos), type):
		return 0
	while queue.size() > 0:
		var current_pos = queue.pop_front()
		
		if visited_positions.has(current_pos):
			continue
		
		visited_positions[current_pos] = true
		
		if check_type(village_map.get_cell_atlas_coords(0, current_pos), type):
			house_count += 1
			
			var neighbours = get_neighbours(current_pos, type)
			for n in neighbours:
				if !visited_positions.has(n):
					queue.append(n)
	
	for v in visited_positions:
		if total_visited.has(v):
			print("hmmm")
		total_visited.push_back(v)
	
	return house_count

# Check if a atlas is a given type
func check_type(pos, type):
	match type:
		"house":
			if pos == Vector2i(0, 0) || pos == Vector2i(0, 2):
				return true
			else:
				return false
		"farm":
			if pos == Vector2i(1, 0):
				return true
			else:
				return false
		"empty":
			if pos == Vector2i(-1, -1):
				return true
			else:
				return false

# Returns neighbours of a given type
func get_neighbours(pos, id):
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]
	
	var neighbors = [pos]
	for direction in directions:
		if check_type(village_map.get_cell_atlas_coords(0, pos + direction), id):
			neighbors.append(pos + direction)
	return neighbors


#################################################################################
############################## VILLAGER PRIORITIES ##############################
#################################################################################

func _on_action_timeout():
	if Global.is_in_disaster:
		$ActionTimer.start()
		return
	
	var available_villagers = []
	var current_jobs = {
		"food" : 0,
		"logging" : 0,
		"mine" : 0,
		"repair" : 0,
		"build" : 0,
		"farm" : 0,
		"new_mine" : 0,
		"construction" : 0
	}
	for v in Global.villager_references:
		if !v.is_working:
			available_villagers.push_back(v)
		else:
			current_jobs[v.job_type] += 1
	
	var priorities = calculate_priorities(current_jobs, available_villagers.size())
	assign_workers(priorities, available_villagers)
	
	print(priorities)
	
	$ActionTimer.start()

func calculate_priorities(current_jobs, num_available_villagers) -> Dictionary:
	var total_villagers = Global.villager_references.size()
	
	var food = max(1, Global.resources["food"])
	var wood = max(1, Global.resources["wood"])
	var materials = max(1, Global.resources["materials"])
	
	var food_priority = float(total_villagers * 30 / food)
	var wood_priority = float(50 / wood)
	var mine_priority = 0.0
	if Global.active_mine_references.size() != 0:
		mine_priority = float(50 / materials)
	
	var num_broken_buildings = Global.get_broken_buildings().size()
	var num_farms = Global.farm_references.size()
	
	var repair_priority = 0.0
	if num_broken_buildings > 0 and wood >= 25: # 25 cost to repair
		repair_priority = float(num_broken_buildings * 25 / wood)
	
	# Add together all the current constructions
	var construction_priority = Global.get_construction_buildings().size()
	
	var build_priority = 0.0
	if num_broken_buildings == 0 and wood >= 50:
		build_priority = float(wood / 50)
	
	var new_farm_priority = 0.0
	if num_farms == 0:
		new_farm_priority = 5.0
	elif total_villagers / Global.farm_references.size() > 10:
		new_farm_priority = float(total_villagers * 10 / Global.farm_references.size())
	
	var new_mine_priority = 0.0
	if wood >= 100:
		var required_mines = Global.farm_references.size() / 5
		if Global.active_mine_references.size() < required_mines:
			new_mine_priority = float(required_mines - Global.active_mine_references.size())
	
	var total_priority = food_priority + wood_priority + mine_priority + repair_priority + build_priority + new_farm_priority + new_mine_priority + construction_priority
	
	var normalized_food = food_priority / total_priority
	var normalized_wood = wood_priority / total_priority
	var normalized_mine = mine_priority / total_priority
	var normalized_repair = repair_priority / total_priority
	var normalized_build = build_priority / total_priority
	var normalized_farm = new_farm_priority / total_priority
	var normalized_new_mine = new_mine_priority / total_priority
	var normalized_construction = construction_priority / total_priority
	
	var food_villagers = max(0, int(normalized_food * total_villagers) - current_jobs["food"])
	var wood_villagers = max(0, int(normalized_wood * total_villagers) - current_jobs["logging"])
	var mine_villagers = max(0, int(normalized_mine * total_villagers) - current_jobs["mine"])
	var repair_villagers = max(0, int(normalized_repair * total_villagers) - current_jobs["repair"])
	var build_villagers = max(0, int(normalized_build * total_villagers) - current_jobs["build"])
	var farm_villagers = max(0, int(normalized_farm * total_villagers) - current_jobs["farm"])
	var new_mine_villagers = max(0, int(normalized_new_mine * total_villagers) - current_jobs["new_mine"])
	var construction_villagers = max(0, int(normalized_construction * total_villagers) - current_jobs["construction"])
	
	var total_assigned_villagers = food_villagers + wood_villagers + mine_villagers + repair_villagers + build_villagers + farm_villagers + new_mine_villagers + construction_villagers
	
	if total_assigned_villagers > num_available_villagers:
		var scale_factor = float(num_available_villagers) / total_assigned_villagers
		food_villagers = int(food_villagers * scale_factor)
		wood_villagers = int(wood_villagers * scale_factor)
		mine_villagers = int(mine_villagers * scale_factor)
		repair_villagers = int(repair_villagers * scale_factor)
		build_villagers = int(build_villagers * scale_factor)
		farm_villagers = int(farm_villagers * scale_factor)
		new_mine_villagers = int(new_mine_villagers * scale_factor)
		construction_villagers = int(construction_villagers * scale_factor)
	
	return {
		"food" : food_villagers,
		"logging" : wood_villagers,
		"mine" : mine_villagers,
		"repair" : repair_villagers,
		"build" : build_villagers,
		"farm" : farm_villagers,
		"new_mine" : new_mine_villagers,
		"construction" : construction_villagers
	}


func assign_workers(priorities, villagers):
	var i = 0
	for p in priorities:
		for v in priorities[p]:
			villagers[i].work(p)
			i += 1
