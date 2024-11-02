extends Resource
class_name Job

signal _on_job_completion

@export var type : Global.JobType
@export var tasks_to_complete : Array[Global.TaskType]

@export var reward_type : Global.RewardType
@export var reward_count : int

var tasks : Array[Task]

var job_completion = false

var current_task : Task = null
var workable : Workable
var villager : Villager

func set_up(in_workable : Workable, in_villager : Villager):
	workable = in_workable
	villager = in_villager
	for t in tasks_to_complete:
		var newTask = Task.create_task(t)
		newTask._on_task_complete.connect(_task_complete)
		newTask.set_up(workable, villager)
		tasks.append(newTask)
	_task_complete(true)

func is_job_complete():
	return job_completion

func add_work_point():
	current_task.add_action_point()

func process_job(delta):
	if current_task != null:
		current_task.run(delta)

func get_job_state():
	return current_task.villager_state()

func _task_complete(was_successful):
	if !was_successful:
		_on_job_completion.emit(type, false)
		tasks.clear()
		current_task = null
		return
	
	if current_task != null:
		current_task.on_exit()
	if tasks.size() > 0:
		current_task = tasks.pop_front()
		current_task.on_enter()
	else:
		Global.give_reward(reward_type, reward_count)
		job_completion = true
		_on_job_completion.emit(type, true)
		current_task = null
