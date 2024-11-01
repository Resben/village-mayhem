extends Node

signal setup_complete
signal _on_speed_changed

enum { NORMAL, FAST, VERY_FAST }

enum JobType { CONSTRUCTION_HOUSE, CONSTRUCTION_FARM, CONSTRUCTION_MINE, RESOURCE_FOOD, RESOURCE_WOOD, RESOURCE_MATERIALS, REPAIR }
enum TaskType { 
	BUILD_HOUSE, BUILD_FARM, BUILD_MINE, REPAIR, # Construction tasks
	ACQUIRE_HOUSE_MATERIAL, ACQUIRE_FARM_MATERIAL, ACQUIRE_MINE_MATERIAL, # Collection tasks
	FARM_FOOD, CUT_TREES, MINE_MATERIALS, # Gathering tasks
	CHOP_WOOD, REFINE_MATERIALS # Refining tasks
	}
enum VillagerState { WORKING, IDLING, SCARED, DEMO, TRAVELLING }
enum RewardType { WOOD, FOOD, MATERIAL, NONE }

var jobtype_string_dictionary = {
	Global.JobType.RESOURCE_FOOD : "resource_food",
	Global.JobType.RESOURCE_WOOD : "resource_wood",
	Global.JobType.RESOURCE_MATERIALS : "resource_material",
	Global.JobType.CONSTRUCTION_HOUSE: "construct_house",
	Global.JobType.CONSTRUCTION_FARM: "construct_farm",
	Global.JobType.CONSTRUCTION_MINE: "construct_mine",
	Global.JobType.REPAIR: "repair"
}

var is_in_disaster = false

var villager_references : Array

var map_size = Vector2i(256, 256)

var docks : Dictionary

var wood_references : Array[Workable]
var house_references : Array[Workable]
var farm_references : Array[Workable]

var inactive_mine_references : Array[Workable]
var active_mine_references : Array[Workable]

var disaster_references = []

var cpu
var population = 0
var hud
var disaster_controller

var controller
var is_setup = false
var is_scene_loaded = false

var current_playback = 1

var main_map : TileMap

var villagers = [
	preload("res://assets/temp/villager_sheet.png")
]

var villager = preload("res://scenes/ai/villager.tscn") as PackedScene

var resources = {
	"food" : 50,
	"wood" : 50,
	"materials" : 0
}

func _process(_delta):
	if is_setup:
		return
	
	if cpu != null && hud != null && is_scene_loaded:
		setup_complete.emit()
		is_setup = true
		hud.update_resources()
		hud.update_population()

func bye_bye():
	wood_references.clear()
	house_references.clear()
	farm_references.clear()
	inactive_mine_references.clear()
	active_mine_references.clear()
	disaster_references.clear()
	villager_references.clear()
	resources = {
		"food" : 50,
		"wood" : 50,
		"materials" : 0
	}
	population = 0
	is_in_disaster = false
	cpu = null
	is_setup = false
	is_scene_loaded = false
	

func get_random_villager() -> Texture2D:
	var rand = randi_range(0, villagers.size())
	return villagers[rand - 1]

func add_population(num):
	population += num
	hud.update_population()

func remove_population(num):
	population -= num
	hud.update_population()

func get_broken_buildings() -> Array[Workable]:
	var refs : Array[Workable]
	for h in house_references:
		if h.is_broken:
			refs.push_back(h)
	
	return refs

func get_construction_buildings() -> Array[Workable]:
	var refs : Array[Workable]
	for h in house_references:
		if h.is_under_construction:
			refs.push_back(h)
	
	return refs

func add_resource(id : String, amount : int):
	resources[id] += amount
	hud.update_resources()

func remove_resources(id : String, amount : int):
	if resources[id] > 0:
		resources[id] -= amount
		hud.update_resources()

func set_game_speed(speed):
	match speed:
		NORMAL:
			_on_speed_changed.emit(1)
			controller.set_speed(1)
			set_speed(1, villager_references)
			current_playback = 1
		FAST:
			_on_speed_changed.emit(2)
			controller.set_speed(2)
			set_speed(2, villager_references)
			current_playback = 2
		VERY_FAST:
			_on_speed_changed.emit(5)
			controller.set_speed(5)
			set_speed(5, villager_references)
			current_playback = 5

func set_speed(value, references):
	for r in references:
		r.set_speed(value)

func is_construction_job(type):
	if type == JobType.CONSTRUCTION_HOUSE || type == JobType.CONSTRUCTION_FARM || type == JobType.CONSTRUCTION_MINE:
		return true
	return false

func is_resource_job(type):
	if type == JobType.RESOURCE_FOOD || type == JobType.RESOURCE_WOOD || type == JobType.RESOURCE_MATERIALS:
		return true
	return false

func jobtype_to_string(type):
	return jobtype_string_dictionary[type]

func get_dock_from_to(start_island : int, end_island: int):
	if start_island == end_island:
		return null
	
	for first in docks:
		for second in docks:
			if first == start_island:
				if second == end_island:
					for first_dock in docks[first]:
						for second_dock in docks[second]:
							if first_dock.data.connected_ocean_id == second_dock.data.connected_ocean_id:
								return [first_dock, second_dock]
	return null
