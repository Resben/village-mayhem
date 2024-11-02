extends Node2D
class_name CPU

@export var village_map : TileMap

var MINIMUM_TOWN_DISTANCE = 500

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

func construct_workable(id):
	var new_location
	var was_random = false
	for townhall in village_map.get_used_cells_by_id(0, 0, Vector2i(0, 2)):
		var workable_count = count_workables(townhall, id)
		if workable_count < 5:
			new_location = get_next_location_in_range(townhall)
		if new_location == null:
			new_location = get_random_location(townhall)
			if new_location != null:
				was_random = true
		if new_location != null:
			break
	
	if new_location != null:
		if was_random && id == "house":
			id = "town_hall"
		return village_map.place_building(id, new_location, true)
	else:
		return null

func count_workables(location, id):
	var count = 0
	var world_position = village_map.map_to_local(location)
	for workable in Global.workable_references[id]:
		if workable.global_position.distance_to(world_position) <= MINIMUM_TOWN_DISTANCE:
			count += 1
	return count

func get_next_location_in_range(location):
	var potential_positions = get_positions_within_radius(location, 3)
	var next_position
	var max_attemps = 0
	while next_position == null || max_attemps == 30:
		var random_position = potential_positions[randi() % potential_positions.size()]
		if village_map.check_availablity(village_map.map_to_local(random_position)):
			next_position = random_position
			break
		potential_positions.erase(random_position)
		max_attemps += 1
	return next_position

func get_positions_within_radius(center : Vector2i, radius : int):
	var positions = []

	for x_offset in range(-radius, radius + 1):
		for y_offset in range(-radius, radius + 1):
			var position = Vector2i(center.x + x_offset, center.y + y_offset)
			positions.append(position)
	
	return positions

func get_random_location(location):
	var next_location
	var world_position = village_map.map_to_local(location)
	var max_attempts = 0
	while next_location == null || max_attempts == 30:
		var possible_location = village_map.get_random_valid_display_position()
		if village_map.map_to_local(possible_location).distance_to(world_position) >= MINIMUM_TOWN_DISTANCE * 2:
			next_location = possible_location
		else:
			max_attempts += 1
	return next_location

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
		if v.state == Global.VillagerState.IDLING:
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
	var farms = Global.workable_references["farm"].size()
	var mines = 0
	
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
		priorities[Global.JobType.CONSTRUCTION_FARM] = float(total_villagers * 10 / farms / max(1, resources["wood"]))
	
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
	
	priorities[Global.JobType.CONSTRUCTION_MINE] = 0.0
	priorities[Global.JobType.RESOURCE_MATERIALS] = 0.0
	priorities[Global.JobType.REPAIR] = 0.0
	
	#print(priorities)
	
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
					workable = find_best_slot(Global.workable_references["farm"], villagers[i])
				Global.JobType.RESOURCE_WOOD:
					workable = find_best_slot(Global.workable_references["wood"], villagers[i])
				Global.JobType.RESOURCE_MATERIALS:
					pass
				Global.JobType.REPAIR:
					pass
				Global.JobType.CONSTRUCTION_HOUSE:
					if Global.resources["wood"] >= 50:
						workable = construct_workable("house")
						if workable:
							Global.remove_resources("wood", 50)
				Global.JobType.CONSTRUCTION_FARM:
					if Global.resources["wood"] >= 10: 
						workable = construct_workable("farm")
						if workable:
							Global.remove_resources("wood", 10)
				Global.JobType.CONSTRUCTION_MINE:
					pass
			
			if workable != null:
				var job = workable.create_job(p, villagers[i])
				i += 1
			else:
				print(Global.jobtype_to_string(p) + " was null")

func find_best_slot(array_of_workplaces : Array, villager_ref : Villager):
	var index = -1
	var i = 0
	var closet = 99999
	for w in array_of_workplaces:
		var distance = w.global_position.distance_to(villager_ref.global_position)
		if distance < closet:
			if w.get_available_workers() > 0:
				closet = distance
				index = i
		i += 1
	if index == -1:
		return null
	else:
		return array_of_workplaces[index]


func _on_food_timer_timeout():
	if Global.controller.state != Controller.GAME:
		Global.remove_resources("food", Global.villager_references.size())
		$Yum.start(randi_range(7, 10))
