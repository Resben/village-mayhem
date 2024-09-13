extends Workable
class_name MineResource

func _ready():
	Global.mine_references.push_back(self)
	required_points = 100

func get_job_type():
	if is_under_construction:
		return "new_mine"
	return "mine"
