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
	villager.set_progress(float(current_points / required_points))
	if current_points == required_points:
		_on_task_complete.emit()
		villager.set_progress(1)

func run(delta):
	pass

func set_up_override():
	pass

class BuildHouseTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.BUILD_HOUSE
		required_points = 100

	func run(delta):
		pass

class BuildFarmTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.BUILD_FARM
		required_points = 100

	func run(delta):
		pass

class BuildMineTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.BUILD_MINE
		required_points = 100

	func run(delta):
		pass

class ResourceFoodTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.FARM_FOOD
		required_points = 50

	func run(delta):
		pass

class ResourceWoodTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.CUT_TREES
		required_points = 50

	func run(delta):
		pass

class ResourceMaterialTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.MINE_MATERIALS
		required_points = 50

	func run(delta):
		pass

class RepairTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.REPAIR
		required_points = 100

	func run(delta):
		pass

class RefineMaterialTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.REFINE_MATERIALS
		required_points = 50

	func run(delta):
		pass

class RefineWoodTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.CHOP_WOOD
		required_points = 50

	func run(delta):
		pass

class AcquireHouseMaterialTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.ACQUIRE_HOUSE_MATERIAL
		required_points = 50

	func run(delta):
		pass

class AcquireFarmMaterialTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.ACQUIRE_FARM_MATERIAL
		required_points = 50

	func run(delta):
		pass

class AcquireMineMaterialTask extends Task:
	func set_up_override():
		task_type = Global.TaskType.ACQUIRE_MINE_MATERIAL
		required_points = 50

	func run(delta):
		pass

static func create_task(type : Global.TaskType):
	match type:
		Global.TaskType.BUILD_FARM:
			return BuildFarmTask.new()
		Global.TaskType.BUILD_HOUSE:
			return BuildHouseTask.new()
		Global.TaskType.BUILD_MINE:
			return BuildMineTask.new()
		Global.TaskType.FARM_FOOD:
			return ResourceFoodTask.new()
		Global.TaskType.CUT_TREES:
			return ResourceWoodTask.new()
		Global.TaskType.MINE_MATERIALS:
			return ResourceMaterialTask.new()
		Global.TaskType.ACQUIRE_HOUSE_MATERIAL:
			return AcquireHouseMaterialTask.new()
		Global.TaskType.ACQUIRE_FARM_MATERIAL:
			return AcquireFarmMaterialTask.new()
		Global.TaskType.ACQUIRE_MINE_MATERIAL:
			return AcquireMineMaterialTask.new()
		Global.TaskType.REPAIR:
			return RepairTask.new()
		Global.TaskType.REFINE_MATERIALS:
			return RefineMaterialTask.new()
		Global.TaskType.CHOP_WOOD:
			return RefineWoodTask.new()
		_:
			print("Ayo this doesn't exist")
			return null
