extends CharacterBody2D
class_name Villager

enum { WORKING, IDLING, SCARED, DEMO }
var state = IDLING
var last_state = IDLING
var last_working_state = IDLING

var panic_locations = []

var job_location
var job_reference
var job_type
var require_job_points = 0
var job_points = 0

@export var is_demo : bool
@export var village_map : TileMap
@onready var nav = $NavigationAgent2D
var direction
var texture : Texture2D
var house : House

var in_house = false
var is_returning = false
var is_working = false

var playback_speed = 1

@onready var original_wait_time = $ActionComplete.wait_time

func _ready():
	$AnimationPlayer.play("walk")
	$Sprite2D.texture = Global.get_random_villager()
	if in_house:
		visible = false
	
	if Global.is_in_disaster:
		on_disaster()
	
	if is_demo:
		state = DEMO
	else:
		playback_speed = Global.hud.current_playback
		$AnimationPlayer.speed_scale = playback_speed

func on_disaster():
	state = SCARED

func disaster_over():
	state = last_working_state
	print(last_working_state)
	exit_house()

func enter_house():
	in_house = true
	visible = false

func exit_house(pos = null):
	if pos != null:
		if is_working:
			nav.target_position = job_location
		else:
			nav.target_position = pos
	visible = true
	in_house = false
	is_returning = false

func work(id):
	match id:
		"food":
			var job = find_best_slot(Global.farm_references)
			if job != null:
				set_job(job)
		"logging":
			var job = find_best_slot(Global.wood_references)
			if job != null:
				set_job(job)
		"mine":
			pass
		"repair":
			pass
		"build":
			if Global.resources["wood"] > 50:
				var job = Global.cpu.construct_house()
				if job != null:
					Global.remove_resources("wood", 50)
					set_job(job)
		"farm":
			if Global.resources["wood"] > 10: 
				var job = Global.cpu.construct_farm()
				if job != null:
					Global.remove_resources("wood", 10)
					set_job(job)
		"new_mine":
			pass
		"construction":
			var job = find_best_slot(Global.get_construction_buildings())
			if job != null:
				set_job(job)

func set_job(job):
	state = WORKING
	job_location = job.get_random_edge_location()
	job_reference = job
	job_type = job.get_job_type() 
	job.add_worker()
	require_job_points = job.required_points
	is_working = true

func set_idle():
	state = IDLING
	is_working = false

func job_complete():
	job_reference.remove_worker()
	match job_type:
		"build":
			set_idle()
		"food":
			set_idle()
			Global.add_resource("food", 10)
		"logging":
			set_idle()
			Global.add_resource("wood", 10)
		"construction":
			set_idle()

func find_best_slot(array_of_workplaces : Array[Workable]) -> Workable:
	var num_spots = 0
	var index = -1
	var i = 0
	for w in array_of_workplaces:
		if w.available_work_slots > num_spots && w.available_work_slots > 0:
			index = i
			num_spots = w.available_work_slots
			i += 1
	if index == -1:
		return null
	else:
		return array_of_workplaces[index]

func _physics_process(delta):
	
	if state != last_state:
		exit_state(last_state)
		enter_state(state)
		last_state = state
	
	run_state(delta, state)
	
	if in_house:
		return
	
	if nav.is_navigation_finished():
		return
	
	var next_path_position = nav.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_position) * 50 * playback_speed
	direction = new_velocity
	
	if nav.avoidance_enabled:
		nav.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	
	move_and_slide()
	
	if direction.x > 0:
		$Sprite2D.flip_h = false
	elif direction.x < 0:
		$Sprite2D.flip_h = true

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity

func exit_state(in_state):
	match in_state:
		WORKING:
			pass
		IDLING:
			pass
		SCARED:
			pass

func enter_state(in_state):
	match in_state:
		WORKING:
			nav.target_position = job_location
			$AnimationPlayer.play("walk")
		IDLING:
			nav.target_position = Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position
			$AnimationPlayer.play("walk")
			$Emotes.set_emote("chilled")
		DEMO:
			nav.target_position = Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position
			$AnimationPlayer.play("walk")
		SCARED:
			$Emotes.set_emote("scared")
			last_working_state = last_state
			var new_direction = (house.door_pos - global_position).normalized()
			var perpendicular = Vector2(-new_direction.y, new_direction.x)
			for i in range(3):
				var t = (i + 1) / 3 + randf_range(0.1, -0.1)
				var point_on_line = global_position.lerp(house.door_pos, t)
				var offset = perpendicular * randf_range(-25, 25)
				panic_locations.push_back(point_on_line + offset)

func run_state(_delta, in_state):
	match in_state:
		WORKING:
			if nav.is_navigation_finished() && $ActionComplete.is_stopped():
				$ActionComplete.start()
				$AnimationPlayer.play(job_type)
				$Emotes.set_emote("work")
		IDLING:
			if nav.is_navigation_finished():
				nav.target_position = Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position
		DEMO:
			if nav.is_navigation_finished():
				nav.target_position = Vector2(randf_range(-100, 100), randf_range(-100, 100)) + global_position
		SCARED:
			if panic_locations.size() > 0 && nav.is_navigation_finished():
				nav.target_position = panic_locations[0]
				panic_locations.remove_at(0)
			elif panic_locations.size() == 0 && !in_house:
				nav.target_position = house.door_pos
			
			if panic_locations.size() == 0 && nav.target_position == house.door_pos:
				if nav.is_navigation_finished():
					enter_house()

func _on_action_complete_timeout():
	job_reference.add_work_point(self)
	if job_type != "construction":
		if job_points >= require_job_points:
			job_complete()
			job_points = 0
		$TextureProgressBar.value = float(job_points) / require_job_points * 100.0

func set_speed(value):
	playback_speed = value
	$AnimationPlayer.speed_scale = value
	$ActionComplete.wait_time = original_wait_time / value

func _on_yum_timeout():
	Global.remove_resources("food", 1)
	$Yum.start(randi_range(7, 10))
