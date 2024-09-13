extends Area2D
class_name HitBox

signal on_break

@export var health : int = 10
@export var type : String

func _ready():
	on_break.connect(get_parent()._on_destroyed)

func take_damage():
	if get_parent().is_broken || get_parent().is_under_construction:
		return
	
	match type:
		"house":
			health -= 1
		"farm":
			Global.remove_resources("food", 1)
		"town_hall":
			health -= 100
			Global.remove_resources("wood", 1)
	
	if health <= 0:
		on_break.emit()
