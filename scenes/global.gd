extends Node

var cpu

var villagers = [
	preload("res://assets/temp/villager_1_sheet.png")
]

var villager = preload("res://scenes/ai/villager.tscn") as PackedScene

func get_random_villager() -> Texture2D:
	var rand = randi_range(0, villagers.size())
	return villagers[rand - 1]
