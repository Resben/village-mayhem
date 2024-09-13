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

# Called by villager to create a new house then assign said villager as a builder
func construct_house():
	var th_location = village_map.get_used_cells_by_id(0, 0, Vector2i(0, 2))[0]
	var new_location = get_next_house_in_cluster(th_location, 8)
	if new_location == null:
		for h in village_map.get_used_cells_by_id(0, 0, Vector2i()):
			new_location = get_next_house_in_cluster(h, 4)
			if new_location != null:
				break
	
	village_map.place_building("house", new_location, true)

func get_next_house_in_cluster(pos : Vector2i, max_cluster : int):
	var visited_positions = {}
	var queue = [pos]
	var house_count = 0
	var next_location = null
	
	if !is_house(village_map.get_cell_atlas_coords(0, pos)):
		return 0
	while queue.size() > 0:
		var current_pos = queue.pop_front()
		
		if visited_positions.has(current_pos):
			continue
		
		visited_positions[current_pos] = true
		
		if is_house(village_map.get_cell_atlas_coords(0, current_pos)):
			house_count += 1
			
			var neighbours = get_neighbours(current_pos)
			for n in neighbours:
				if is_house(village_map.get_cell_atlas_coords(0, n)) and !visited_positions.has(n):
					queue.append(n)
				elif next_location == null && village_map.get_cell_atlas_coords(0, n) == Vector2i(-1, -1):
					next_location = n
	
	return next_location

func is_house(pos):
	if pos == Vector2i(0, 0) || pos == Vector2i(0, 2):
		return true
	else:
		return false

func get_neighbours(pos):
	var directions = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]
	
	var neighbors = []
	for direction in directions:
		neighbors.append(pos + direction)
	return neighbors


#################################################################################
############################## VILLAGER PRIORITIES ##############################
#################################################################################

func _on_action_timeout():
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
		if Global.mine_references.size() < required_mines:
			new_mine_priority = float(required_mines - Global.mine_references.size())
	
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
