extends Resource
class_name Task
signal _on_task_complete

var task_type : Global.TaskType
var required_points : int

var current_points = 0
var task_complete = false

var workable : Workable
var villager : Villager

func set_up(in_workable : Workable, in_villager : Villager):
	workable = in_workable
	villager = in_villager
	set_up_override()

func add_action_point():
	if task_complete:
		return
	current_points += 1
	villager.set_progress(float(current_points) / required_points)
	if current_points == required_points:
		_on_task_complete.emit()
		villager.set_progress(1)

func set_data(type, points):
	task_type = type
	required_points = points

func on_enter():
	pass

func run(delta):
	pass

func set_up_override():
	pass

###################################################################
############################## TASKS ##############################
###################################################################

class ActionTask extends Task:
	func on_enter():
		pass

	func run(delta):
		if villager.global_position.distance_to(workable.global_position) > 50:
			villager.navigation_component.set_target_position(workable.global_position)
		else:
			villager.start_work(task_type)

class RefineMaterialTask extends Task:
	func on_enter():
		pass

	func run(delta):
		if villager.global_position.distance_to(workable.global_position) > 50:
			villager.navigation_component.set_target_position(workable.global_position)
		else:
			villager.start_work(task_type)

class RefineWoodTask extends Task:
	func on_enter():
		pass

	func run(delta):
		if villager.global_position.distance_to(workable.global_position) > 50:
			villager.navigation_component.set_target_position(workable.global_position)
		else:
			villager.start_work(task_type)

class AcquireTask extends Task:
	func on_enter():
		pass

	func run(delta):
		if villager.global_position.distance_to(workable.global_position) > 50:
			villager.navigation_component.set_target_position(workable.global_position)
		else:
			villager.start_work(task_type)

###################################################################
############################# FACTORY #############################
###################################################################

static func create_task(type : Global.TaskType):
	match type:
		Global.TaskType.BUILD_FARM:
			var task = ActionTask.new()
			task.set_data(type, 100)
			return task
		Global.TaskType.BUILD_HOUSE:
			var task = ActionTask.new()
			task.set_data(type, 100)
			return task
		Global.TaskType.BUILD_MINE:
			var task = ActionTask.new()
			task.set_data(type, 100)
			return task
		Global.TaskType.FARM_FOOD:
			var task = ActionTask.new()
			task.set_data(type, 30)
			return task
		Global.TaskType.CUT_TREES:
			var task = ActionTask.new()
			task.set_data(type, 50)
			return task
		Global.TaskType.MINE_MATERIALS:
			var task = ActionTask.new()
			task.set_data(type, 200)
			return task
		Global.TaskType.ACQUIRE_HOUSE_MATERIAL:
			var task = AcquireTask.new()
			task.set_data(type, 5)
			return task
		Global.TaskType.ACQUIRE_FARM_MATERIAL:
			var task = AcquireTask.new()
			task.set_data(type, 5)
			return task
		Global.TaskType.ACQUIRE_MINE_MATERIAL:
			var task = AcquireTask.new()
			task.set_data(type, 5)
			return task
		Global.TaskType.REPAIR:
			var task = ActionTask.new()
			task.set_data(type, 100)
			return task
		Global.TaskType.REFINE_MATERIALS:
			var task = RefineMaterialTask.new()
			task.set_data(type, 100)
			return task
		Global.TaskType.CHOP_WOOD:
			var task = RefineWoodTask.new()
			task.set_data(type, 50)
			return task
		_:
			print("Ayo this doesn't exist")
			return null
