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
	_task_complete()

func is_job_complete():
	return job_completion

func add_work_point():
	current_task.add_action_point()

func process_job(delta):
	if current_task != null:
		current_task.run(delta)

func _task_complete():
	if tasks.size() > 0:
		current_task = tasks.pop_front()
	else:
		job_completion = true
		_on_job_completion.emit()
		current_task = null
