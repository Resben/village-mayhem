extends Node2D
class_name CPU

@export var village_map : TileMap

var villagers = []

func _ready():
	Global.cpu = self

func add_villager(villager : Villager):
	add_child(villager)
	villagers.push_back(villager)

func on_disaster():
	for v in villagers:
		v.return_to_house()
