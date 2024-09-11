extends Node2D
class_name Workable

var available_work_slots = 3
var work_radius = 45

@export var underconstruction : Texture2D
@export var built : Texture2D
@export var destroyed : Texture2D

var work_id = "not_set"
var work_points = 0
var required_points = 0

var is_under_construction = true
var construction_percentage = 0

func add_worker():
	available_work_slots -= 1
	if is_under_construction:
		return "construction"
	else:
		return work_id

func get_random_edge_location():
	var angle = randf_range(0, TAU)
	var x = work_radius * cos(angle)
	var y = work_radius * sin(angle)
	return Vector2(x, y) + global_position

func add_work_point(reference : Villager):
	if is_under_construction:
		construction_percentage += 1
		if construction_percentage == 100:
			is_under_construction = false
			$Sprite2D.texture = built
			reference.job_complete()
	else:
		reference.job_points += 1

func was_destroyed():
	is_under_construction = true
	construction_percentage = 0
	$Sprite2D.texture = destroyed
