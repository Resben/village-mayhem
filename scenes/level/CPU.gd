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

func _on_action_timeout():
	var available_villagers = []
	for v in Global.villager_references:
		if !v.is_working:
			available_villagers.push_back(v)
	
	var priorities = calculate_priorities(available_villagers.size())
	assign_workers(priorities, available_villagers)
	
	print(priorities)
	
	$ActionTimer.start()

func calculate_priorities(num_available_villagers) -> Dictionary:
	var total_villagers = Global.villager_references.size()
	
	if Global.resources["food"] < 1:
		Global.resources["food"] = 1
	if Global.resources["wood"] < 1:
		Global.resources["wood"] = 1
	if Global.resources["materials"] < 1:
		Global.resources["materials"] = 1
	
	var food_priority = float(total_villagers * 30 / Global.resources["food"])
	var wood_priority = float(50 / Global.resources["wood"])
	var mine_priority = 0.0
	if Global.mine_references.size() != 0:
		mine_priority = float(50 / Global.resources["materials"])
	
	var num_broken_buildings = Global.get_broken_buildings().size()
	var num_farms = Global.farm_references.size()
	
	var repair_priority = 0.0
	if num_broken_buildings > 0 and Global.resources["wood"] >= 25: # 25 cost to repair
		repair_priority = float(num_broken_buildings * 25 / Global.resources["wood"])
	
	var build_priority = 0.0
	if num_broken_buildings == 0 and Global.resources["wood"] >= 50:
		build_priority = float(Global.resources["wood"] / 50)
	
	var new_farm_priority = 0.0
	if num_farms == 0:
		new_farm_priority = 5.0
	elif total_villagers / Global.farm_references.size() > 10:
		new_farm_priority = float(total_villagers * 10 / Global.farm_references.size())
	
	var new_mine_priority = 0.0
	if Global.resources["wood"] >= 100:
		var required_mines = Global.farm_references.size() / 5
		if Global.mine_references.size() < required_mines:
			new_mine_priority = float(required_mines - Global.mine_references.size())
	
	var total_priority = food_priority + wood_priority + mine_priority + repair_priority + build_priority + new_farm_priority + new_mine_priority
	
	var normalized_food = food_priority / total_priority
	var normalized_wood = wood_priority / total_priority
	var normalized_mine = mine_priority / total_priority
	var normalized_repair = repair_priority / total_priority
	var normalized_build = build_priority / total_priority
	var normalized_farm = new_farm_priority / total_priority
	var normalized_new_mine = new_mine_priority / total_priority
	
	var food_villagers = int(normalized_food * num_available_villagers)
	var wood_villagers = int(normalized_wood * num_available_villagers)
	var mine_villagers = int(normalized_mine * num_available_villagers)
	var repair_villagers = int(normalized_repair * num_available_villagers)
	var build_villagers = int(normalized_build * num_available_villagers)
	var farm_villagers = int(normalized_farm * num_available_villagers)
	var new_mine_villagers = int(normalized_new_mine * num_available_villagers)
	
	return {
		"food" : food_villagers,
		"wood" : wood_villagers,
		"mine" : mine_villagers,
		"repair" : repair_villagers,
		"build" : build_villagers,
		"farm" : farm_villagers,
		"new_mine" : new_mine_villagers
	}


func assign_workers(priorities, villagers):
	var i = 0
	for p in priorities:
		for v in priorities[p]:
			villagers[i].work(p)
			i += 1
