extends Workable
class_name MineResource

func _ready():
	super._ready()
	Global.workable_references["mine"].push_back(self)
