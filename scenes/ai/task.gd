extends Resource
class_name Task
signal _on_task_complete

var task_type : Global.TaskType
var required_points : int

var internal_villager_state = Global.VillagerState.WORKING

var current_points = 0
var task_complete = false

var process_action_points = true

var workable : Workable
var villager : Villager

var variables = {}

func villager_state():
	return internal_villager_state

func set_up(in_workable : Workable, in_villager : Villager):
	workable = in_workable
	villager = in_villager
	set_up_override()

func add_action_point():
	if task_complete:
		return
	on_action_point()
	if process_action_points:
		current_points += 1
	if current_points == required_points:
		on_task_completion()
		_on_task_complete.emit(true)

func throw_task_fail():
	_on_task_complete.emit(false)

func set_data(type, points):
	task_type = type
	required_points = points

func on_action_point():
	pass

func on_task_completion():
	pass

func on_enter():
	pass

func on_exit():
	pass

func run(delta):
	pass

func set_up_override():
	pass

###################################################################
############################## TASKS ##############################
###################################################################

class ActionTask extends Task:
	func on_action_point():
		villager.set_progress(float(current_points) / required_points)

	func on_task_completion():
		villager.set_progress(1)

	func on_enter():
		variables["target_position"] = workable.get_random_edge_location()
		if !villager.travel_to(variables["target_position"]):
			throw_task_fail()
			print("Failed task")
		internal_villager_state = Global.VillagerState.TRAVELLING
		villager.emotes.set_emote("none")

	func on_exit():
		villager.emotes.set_emote("none")

	func run(delta):
		if villager.navigation_component.get_navigation_target() == variables["target_position"] && villager.navigation_component.is_navigation_finished():
			villager.state = Global.VillagerState.WORKING
			internal_villager_state = Global.VillagerState.WORKING
			villager.start_work(task_type)
			villager.emotes.set_emote("work")

class BuildTask extends Task:
	func set_up_override():
		current_points = workable.health_component.current_health
		required_points = workable.health_component.max_health
		process_action_points = false
	
	func on_action_point():
		workable.health_component.heal(1)
		current_points = workable.health_component.current_health
	
	func on_enter():
		variables["target_position"] = workable.get_random_edge_location()
		if !villager.travel_to(variables["target_position"]):
			throw_task_fail()
		internal_villager_state = Global.VillagerState.TRAVELLING
		villager.emotes.set_emote("none")

	func on_exit():
		villager.emotes.set_emote("none")

	func run(delta):
		if villager.navigation_component.get_navigation_target() == variables["target_position"] && villager.navigation_component.is_navigation_finished():
			villager.state = Global.VillagerState.WORKING
			internal_villager_state = Global.VillagerState.WORKING
			villager.start_work(task_type)
			villager.emotes.set_emote("work")

###################################################################
############################# FACTORY #############################
###################################################################

static func create_task(type : Global.TaskType):
	match type:
		Global.TaskType.BUILD_FARM:
			return BuildTask.new()
		Global.TaskType.BUILD_HOUSE:
			return BuildTask.new()
		Global.TaskType.BUILD_MINE:
			return BuildTask.new()
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
			var task = ActionTask.new()
			task.set_data(type, 5)
			return task
		Global.TaskType.ACQUIRE_FARM_MATERIAL:
			var task = ActionTask.new()
			task.set_data(type, 5)
			return task
		Global.TaskType.ACQUIRE_MINE_MATERIAL:
			var task = ActionTask.new()
			task.set_data(type, 5)
			return task
		Global.TaskType.REPAIR:
			var task = ActionTask.new()
			task.set_data(type, 100)
			return task
		Global.TaskType.REFINE_MATERIALS:
			var task = ActionTask.new()
			task.set_data(type, 100)
			return task
		Global.TaskType.CHOP_WOOD:
			var task = ActionTask.new()
			task.set_data(type, 50)
			return task
		_:
			print("Ayo this doesn't exist")
			return null
