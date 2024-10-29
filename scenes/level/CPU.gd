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
	var num_farms
	for l in village_map.get_used_cells_by_id(0, 0, Vector2i(1, 0)):
		if !total_visited_locations.has(l):
			num_farms = count_cluster(l, total_visited_locations, "farm")
			if num_farms < 4:
				next_location = get_next_location(l, "farm")
				if next_location != null:
					print("Found existing location for farm")
					break
	
	if next_location == null:
		next_location = village_map.get_random_valid_display_position()
		print("Created new random location for farm")
	
	if next_location != null:
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
	
	print(str(total_neighbours.size()) + " neighbours found for next location")
	
	while next_location == null:
		if total_neighbours.size() == 0:
			break
		var next_neighbour = total_neighbours[randi_range(0, total_neighbours.size()) - 1]
		var empty_neigbours = get_neighbours(next_neighbour, "empty")
		if empty_neigbours.size() != 0:
			var next_empty = empty_neigbours[randi_range(0, empty_neigbours.size()) - 1]
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
		Global.JobType.RESOURCE_FOOD : 0,
		Global.JobType.RESOURCE_WOOD : 0,
		Global.JobType.RESOURCE_MATERIALS : 0,
		Global.JobType.CONSTRUCTION_HOUSE: 0,
		Global.JobType.CONSTRUCTION_FARM: 0,
		Global.JobType.CONSTRUCTION_MINE: 0,
		Global.JobType.REPAIR: 0
	}
	for v in Global.villager_references:
		if v.state != Global.VillagerState.WORKING:
			available_villagers.push_back(v)
		else:
			current_jobs[v.job_reference.type] += 1
	
	var priorities = calculate_priorities(current_jobs, available_villagers.size())
	
	var debug_print = ""
	for p in priorities:
		debug_print += Global.jobtype_to_string(p) + " : " + str(priorities[p]) + ", "
	print(debug_print)
	
	assign_workers(priorities, available_villagers)
	
	$ActionTimer.start()

func calculate_priorities(current_jobs, num_available_villagers) -> Dictionary:
	if num_available_villagers == 0:
		return {}
	
	var total_villagers = Global.villager_references.size()
	var resources = Global.resources
	var broken_buildings = Global.get_broken_buildings().size()
	var farms = Global.farm_references.size()
	var mines = Global.active_mine_references.size()
	
	# Initialize priorities dictionary
	var priorities = {
		Global.JobType.RESOURCE_FOOD: float(total_villagers * 30 / max(1, resources["food"])),
		Global.JobType.RESOURCE_WOOD: float(50 / max(1, resources["wood"])),
		Global.JobType.RESOURCE_MATERIALS: 0.0,
		Global.JobType.CONSTRUCTION_HOUSE: 0,
		Global.JobType.CONSTRUCTION_FARM: 0,
		Global.JobType.CONSTRUCTION_MINE: 0,
		Global.JobType.REPAIR: 0
	}
	
	# Set conditional values separately
	if mines > 0:
		priorities[Global.JobType.RESOURCE_MATERIALS] = float(50 / max(1, resources["materials"]))
	
	if broken_buildings > 0 and resources["wood"] >= 25:
		priorities[Global.JobType.REPAIR] = float(broken_buildings * 25 / max(1, resources["wood"]))
	
	if broken_buildings == 0 and resources["wood"] >= 50:
		priorities[Global.JobType.CONSTRUCTION_HOUSE] = float(resources["wood"] / 50)
	
	if total_villagers / farms > 10:
		priorities[Global.JobType.CONSTRUCTION_FARM] = float(total_villagers * 10 / farms * 10 / max(1, resources["wood"]))
	
	if resources["wood"] >= 100 and mines < farms / 5:
		priorities[Global.JobType.CONSTRUCTION_MINE] = float(farms / 5 - mines)
	
	# Normalize priorities to avoid extreme differences
	var total_priority = 0.0
	for value in priorities.values():
		total_priority += value
	
	# Ensure all tasks receive a minimum allocation for fairness
	var min_allocation = 0.1
	for key in priorities.keys():
		priorities[key] = max(priorities[key] / total_priority, min_allocation)
	
	# Allocate villagers proportionally
	var allocated_villagers = {}
	var total_assigned_villagers = 0
	
	for key in priorities.keys():
		var assigned = int(priorities[key] * num_available_villagers) - current_jobs.get(key, 0)
		allocated_villagers[key] = max(0, assigned)
		total_assigned_villagers += allocated_villagers[key]
	
	# Scale down if over-allocated due to rounding
	if total_assigned_villagers > num_available_villagers:
		var scale_factor = float(num_available_villagers) / total_assigned_villagers
		for key in allocated_villagers.keys():
			allocated_villagers[key] = int(allocated_villagers[key] * scale_factor)
	
	return allocated_villagers


func assign_workers(priorities, villagers):
	var i = 0
	for p in priorities:
		for v in priorities[p]:
			var workable
			match p:
				Global.JobType.RESOURCE_FOOD:
					workable = find_best_slot(p, Global.farm_references)
				Global.JobType.RESOURCE_WOOD:
					workable = find_best_slot(p, Global.wood_references)
				Global.JobType.RESOURCE_MATERIALS:
					pass
				Global.JobType.REPAIR:
					pass
				Global.JobType.CONSTRUCTION_HOUSE:
					if Global.resources["wood"] > 50:
						workable = construct_house()
				Global.JobType.CONSTRUCTION_FARM:
					if Global.resources["wood"] > 10: 
						workable = construct_farm()
				Global.JobType.CONSTRUCTION_MINE:
					pass
			
			if workable != null:
				var job = workable.create_job(p, villagers[i])
				i += 1
			else:
				priorities.erase(p)
				print(Global.jobtype_to_string(p) + " was null")

func find_best_slot(job_id, array_of_workplaces : Array[Workable]) -> Workable:
	var num_spots = 0
	var index = -1
	var i = 0
	for w in array_of_workplaces:
		if w.available_work_slots > num_spots && w.available_work_slots > 0:
			index = i
			num_spots = w.available_work_slots
			i += 1
	if index == -1:
		return null
	else:
		return array_of_workplaces[index]
