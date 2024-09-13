extends Workable
class_name House

var residents = []

@export var is_townhall : bool
@onready var door_pos = $Door.global_position

var villagers_left = 0

func _ready():
	Global.setup_complete.connect(_on_world_setup)

func get_job_type():
	if !is_under_construction:
		push_error("You tried to get a job type on a built house?")
	return "construction"

func _on_world_setup():
	if is_townhall:
		is_under_construction = false
		spawn_villagers()
		$Sprite2D.texture = built
	else:
		$Sprite2D.texture = underconstruction

func leave_house():
	$LeaveHouse.start()
	villagers_left = 0

func _on_leave_house_timeout():
	if villagers_left < residents.size():
		residents[villagers_left].exit_house(Vector2(randi_range(40, 80), randi_range(40, 80)) + global_position)
		$LeaveHouse.start()
		villagers_left += 1

func on_house_destroyed():
	Global.remove_population(residents.size())

func on_house_repaired():
	Global.add_population(residents.size())

func spawn_villagers():
	var rand_villagers
	if is_townhall:
		rand_villagers = randi_range(5, 10)
	else:
		rand_villagers = randi_range(2, 5)
	
	Global.add_population(rand_villagers)
	
	for i in rand_villagers:
		var vill = Global.villager.instantiate()
		vill.global_position = door_pos
		vill.in_house = true
		vill.house = self
		Global.cpu.add_villager(vill)
		residents.push_back(vill)
	leave_house()
