extends Node

signal setup_complete

var villager_references : Array
var house_references : Array[Workable]
var farm_references : Array[Workable]
var mine_references : Array[Workable]

var cpu
var population = 0
var hud

var is_setup = false

var villagers = [
	preload("res://assets/temp/villager_1_sheet.png")
]

var villager = preload("res://scenes/ai/villager.tscn") as PackedScene

var resources = {
	"food" : 0,
	"wood" : 0,
	"materials" : 0
}

func _process(delta):
	if is_setup:
		return
	
	if cpu != null && hud != null:
		setup_complete.emit()
		is_setup = true
		hud.update_resources()
		hud.update_population()

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

func add_resource(id : String, amount : int):
	resources[id] += amount
	hud.update_resources()

func remove_resources(id : String, amount : int):
	resources[id] -= amount
	hud.update_resources()
