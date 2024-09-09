extends Node2D
class_name House

var residents = []

@onready var door_pos = $Door.global_position
var villagers_left = 0

func _ready():
	var rand_villagers = randi_range(2, 5)
	for i in rand_villagers:
		var vill = Global.villager.instantiate()
		vill.global_position = door_pos
		vill.in_house = true
		vill.house = self
		Global.cpu.add_villager(vill)
		residents.push_back(vill)
	leave_house()

func leave_house():
	$LeaveHouse.start()
	villagers_left = 0

func _on_leave_house_timeout():
	if villagers_left < residents.size():
		residents[villagers_left].exit_house(Vector2(randi_range(40, 80), randi_range(40, 80)) + global_position)
		$LeaveHouse.start()
		villagers_left += 1
