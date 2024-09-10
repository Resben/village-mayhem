extends Node

var villager_references = []
var house_references = []
var farm_references = []
var mine_references = []

var cpu
var population = 0
var hud

var villagers = [
	preload("res://assets/temp/villager_1_sheet.png")
]

var villager = preload("res://scenes/ai/villager.tscn") as PackedScene

func get_random_villager() -> Texture2D:
	var rand = randi_range(0, villagers.size())
	return villagers[rand - 1]

func add_population(num):
	population += num
	hud.update_population()

func remove_population(num):
	population -= num
	hud.update_population()

func get_broken_buildings():
	var refs = []
	for h in house_references:
		if h.is_broken:
			refs.push_back(h)
	
	return refs
