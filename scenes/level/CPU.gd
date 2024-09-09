extends Node2D
class_name CPU

@export var village_map : TileMap

var villagers = []

func _ready():
	var test_villi = Global.villager.instantiate()
	test_villi.global_position = Vector2(488, 304)
	villagers.push_back(test_villi)
	add_child(test_villi)
