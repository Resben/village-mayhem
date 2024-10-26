extends Node

signal setup_complete
signal _on_speed_changed

enum { NORMAL, FAST, VERY_FAST }

var is_in_disaster = false

var villager_references : Array

var map_size = Vector2i(256, 256)

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
	
	if cpu != null && hud != null:
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
		FAST:
			_on_speed_changed.emit(2)
			controller.set_speed(2)
			set_speed(2, villager_references)
		VERY_FAST:
			_on_speed_changed.emit(5)
			controller.set_speed(5)
			set_speed(5, villager_references)

func set_speed(value, references):
	for r in references:
		r.set_speed(value)
