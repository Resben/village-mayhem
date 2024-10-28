extends Resource
class_name Job

signal _on_job_completion

@export var type : Global.JobType
@export var tasks : Array[Task]

var job_completion = false

var current_task : Task = null
var workable : Workable
var villager : Villager

func set_up():
	for t in tasks:
		t._on_task_complete.connect(_task_complete)
		t.set_up(workable, villager)

func assign_villager(villager_ref : Villager):
	if workable == null:
		print("Invalid job")
		return
	villager = villager_ref
	set_up()

func is_job_complete():
	return job_completion

func process_job(delta):
	if current_task != null:
		current_task.run(villager)

func _task_complete():
	if tasks.size() > 0:
		current_task = tasks.pop_front()
	else:
		job_completion = true
		_on_job_completion.emit()
		current_task = null
