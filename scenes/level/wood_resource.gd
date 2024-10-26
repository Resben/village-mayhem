extends Workable
class_name WoodResource

func _ready():
	super._ready()
	Global.wood_references.push_back(self)
	required_points = 50
	state = BUILT
	work_radius = 45

func get_job_type():
	return "logging"
