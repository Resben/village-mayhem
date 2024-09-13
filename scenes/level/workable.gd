extends Node2D
class_name Workable

var available_work_slots = 3
var work_radius = 30

@export var underconstruction : Texture2D
@export var built : Texture2D
@export var destroyed : Texture2D

var work_points = 0
var required_points = 0

var is_under_construction = true
var construction_percentage = 0
var repair_percentage = 0
var is_broken = false

func _ready():
	if is_under_construction:
		$TextureProgressBar.visible = true
	else:
		$TextureProgressBar.visible = false

func add_worker():
	available_work_slots -= 1

func get_job_type():
	pass

func get_random_edge_location():
	var angle = randf_range(0, TAU)
	var x = work_radius * cos(angle)
	var y = work_radius * sin(angle)
	return Vector2(x, y) + global_position

func add_work_point(reference : Villager):
	if reference.job_type == "construction":
		if is_under_construction:
			construction_percentage += 5
			if construction_percentage == 100:
				is_under_construction = false
				$Sprite2D.texture = built
				reference.job_complete()
				$TextureProgressBar.visible = false
				on_construction_complete()
			$TextureProgressBar.value = construction_percentage
		else:
			reference.job_complete()
	elif reference.job_type == "repair":
		if is_broken:
			repair_percentage += 1
			if repair_percentage == 100:
				is_broken = false
				$Sprite2D.texture = built
				reference.job_complete()
				$TextureProgressBar.visible = false
				on_repair_complete()
			$TextureProgressBar.value = repair_percentage
		else:
			reference.job_complete()
	else:
		reference.job_points += 5

func _on_destroyed():
	is_broken = true
	repair_percentage = 0
	$Sprite2D.texture = destroyed
	$TextureProgressBar.visible = true

func on_construction_complete():
	pass

func on_repair_complete():
	pass
