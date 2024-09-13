extends Workable
class_name Farm

func _ready():
	Global.farm_references.push_back(self)
	required_points = 30

func get_job_type():
	if is_under_construction:
		return "farm"
	return "food"
