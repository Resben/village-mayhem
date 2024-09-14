extends Node

signal setup_complete

var villager_references : Array

var wood_references : Array[Workable]
var house_references : Array[Workable]
var farm_references : Array[Workable]

var inactive_mine_references : Array[Workable]
var active_mine_references : Array[Workable]

var disaster_references = []

var current_bgm = "peaceful"
var bgm_volume = 1.0
var sfx_volume = 1.0

var cpu
var population = 0
var hud
var disaster_controller

var is_setup = false

var villagers = [
	preload("res://assets/temp/villager_1_sheet.png")
]

var villager = preload("res://scenes/ai/villager.tscn") as PackedScene

var resources = {
	"food" : 200,
	"wood" : 200,
	"materials" : 0
}

func _process(delta):
	if disaster_references.size() > 0:
		switch_bgm("chaos")
	else:
		switch_bgm("peaceful")
	
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

func switch_bgm(id):
	if id == current_bgm:
		return
	
	current_bgm = id
	var tween = get_tree().create_tween()
	tween.tween_property($BGM, "volume_db", linear_to_db(0.0), 7.5)
	tween.tween_callback(next_track)

func next_track():
	if current_bgm == "peaceful":
		pass #$BGM.play("peaceful")
	else:
		pass #BGM.play("chaos")
	
	var tween = get_tree().create_tween()
	tween.tween_property($BGM, "volume_db", linear_to_db(bgm_volume), 7.5)

func play_SFX(id):
	pass
