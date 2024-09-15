extends Node2D
class_name Workable

var available_work_slots = 3
var work_radius = 30

var work_points = 0
var required_points = 0

var is_under_construction = true
var construction_percentage = 0
var repair_percentage = 100
var is_broken = false

var is_windy = false

var playback_speed = 1

func _ready():
	playback_speed = Global.hud.current_playback
	$AnimationPlayer.speed_scale = playback_speed
	
	if is_under_construction:
		$TextureProgressBar.visible = true
	else:
		$TextureProgressBar.visible = false

func _process(delta):
	if is_under_construction:
		if is_windy:
			$AnimationPlayer.play("windy_underconstruction")
		else:
			$AnimationPlayer.play("underconstruction")
	elif is_broken:
		if is_windy:
			$AnimationPlayer.play("windy_broken")
		else:
			$AnimationPlayer.play("broken")
	elif repair_percentage < 50:
		if is_windy:
			$AnimationPlayer.play("windy_damaged")
		else:
			$AnimationPlayer.play("damaged")
	else:
		if is_windy:
			$AnimationPlayer.play("windy_fixed")
		else:
			$AnimationPlayer.play("fixed")

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
			construction_percentage += 5 * playback_speed
			if construction_percentage >= 100:
				is_under_construction = false
				reference.job_complete()
				$TextureProgressBar.visible = false
				on_construction_complete()
			$TextureProgressBar.value = construction_percentage
		else:
			reference.job_complete()
	elif reference.job_type == "repair":
		if is_broken:
			repair_percentage += 1 * playback_speed
			if repair_percentage >= 100:
				is_broken = false
				reference.job_complete()
				$TextureProgressBar.visible = false
				on_repair_complete()
			$TextureProgressBar.value = repair_percentage
		else:
			reference.job_complete()
	else:
		reference.job_points += 1 * playback_speed

func _on_destroyed():
	is_broken = true
	repair_percentage = 0
	$TextureProgressBar.visible = true

func on_construction_complete():
	pass

func on_repair_complete():
	pass

func set_wind(boo : bool):
	is_windy = boo

func set_speed(value):
	playback_speed = value
	$AnimationPlayer.speed_scale = value
