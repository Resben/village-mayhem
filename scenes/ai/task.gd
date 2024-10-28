extends Resource
class_name Task

signal _on_task_complete

@export var task_type : Global.TaskType
@export var required_points : int

var current_points = 0
var task_complete = false

var workable : Workable
var villager : Villager

func add_action_point():
	if task_complete:
		return
	current_points += 1
	villager.set_progress(float(current_points / required_points))
	if current_points == required_points:
		_on_task_complete.emit()
		villager.set_progress(1)

func add_location(location : Workable, villager_ref : Villager):
	workable = location
	villager = villager_ref

func run(delta):
	if villager.global_position != workable.global_position:
		villager.travel_to(workable.global_position)
	else:
		villager.start_work(task_type)
