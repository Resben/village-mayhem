extends Workable
class_name Farm

func _ready():
	Global.farm_references.push_back(self)
