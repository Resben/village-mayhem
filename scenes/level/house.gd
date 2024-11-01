extends Workable
class_name House

var residents = []

@export var is_townhall : bool
@onready var door_pos = $Door.global_position

var villagers_left = 0

func _ready():
	super._ready()
	Global.workable_references["house"].push_back(self)
	Global.setup_complete.connect(_on_world_setup)

func get_job_type():
	if state != CONSTRUCTION:
		push_error("You tried to get a job type on a built house?")
	return "construction"

func _on_world_setup():
	if is_townhall:
		state = BUILT
		spawn_villagers()

func leave_house():
	if !Global.is_in_disaster:
		$LeaveHouse.start()
		villagers_left = 0

func _on_leave_house_timeout():
	if Global.is_in_disaster:
		return
	
	if villagers_left < residents.size():
		residents[villagers_left].exit_house(Vector2(randi_range(40, 80), randi_range(40, 80)) + global_position)
		$LeaveHouse.start()
		villagers_left += 1

func _on_destroyed():
	if state == BROKEN:
		return
	super._on_destroyed()
	Global.remove_population(residents.size())
	for r in residents:
		Global.villager_references.erase(r)
		r.queue_free()
	residents.clear()

func on_repair_complete():
	spawn_villagers()

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
