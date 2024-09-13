extends Workable
class_name WoodResource

func _ready():
	super._ready()
	Global.wood_references.push_back(self)
	required_points = 50
	is_under_construction = false

func get_job_type():
	return "logging"
