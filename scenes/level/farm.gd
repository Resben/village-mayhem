extends Workable
class_name Farm

func _ready():
	super._ready()
	Global.workable_references["farm"].push_back(self)
	state = BUILT

func get_job_type():
	return "food"
