extends Workable
class_name Farm

func _ready():
	Global.farm_references.push_back(self)
	work_id = "farming"
	required_points = 30

