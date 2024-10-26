extends Workable
class_name Farm

func _ready():
	super._ready()
	Global.farm_references.push_back(self)
	required_points = 30
	state = BUILT

func get_job_type():
	return "food"
