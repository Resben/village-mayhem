extends CharacterBody2D
class_name Villager

enum { WORKING, IDLING, SCARED }
var state = IDLING
var last_state = IDLING

var panic_locations = []

var job_location
var job_reference
var job_type
var require_job_points = 0
var job_points = 0

@onready var nav = $NavigationAgent2D
var direction
var texture : Texture2D
var house : House

var in_house = false
var is_returning = false
var is_working = false

func _ready():
	$Sprite2D.texture = Global.get_random_villager()
	if in_house:
		visible = false

func go_to(pos):
	nav.target_position = pos

func on_disaster():
	state = SCARED

func enter_house():
	in_house = true
	visible = false

func exit_house(pos):
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
		"wood":
			pass
		"mine":
			pass
		"repair":
			pass
		"build":
			pass
		"farm":
			pass
		"new_mine":
			pass

func set_job(job):
	state = WORKING
	job_location = job.get_random_edge_location()
	job_reference = job
	job_type = job.add_worker()
	require_job_points = job.required_points
	is_working = true

func set_idle():
	state = IDLING
	is_working = false

func job_complete():
	job_reference.available_work_slots += 1
	match job_type:
		"construction":
			set_idle()
		"farming":
			set_idle()
			Global.add_resource("food", 10)

func find_best_slot(array_of_workplaces : Array[Workable]) -> Workable:
	var num_spots = 0
	var index = -1
	var i = 0
	for w in array_of_workplaces:
		if w.available_work_slots > num_spots:
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
	var new_velocity = global_position.direction_to(next_path_position) * 100
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

func exit_state(state):
	match state:
		WORKING:
			pass
		IDLING:
			pass
		SCARED:
			pass

func enter_state(state):
	match state:
		WORKING:
			nav.target_position = job_location
			$AnimationPlayer.play("walk")
		IDLING:
			nav.target_position = Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position
			$AnimationPlayer.play("walk")
		SCARED:
			#$AnimationPlayer.play("scared")
			var direction = (house.door_pos - global_position).normalized()
			var perpendicular = Vector2(-direction.y, direction.x)
			for i in range(3):
				var t =(i + 1) / 3 + randf_range(0.1, -0.1)
				var point_on_line = global_position.lerp(house.door_pos, t)
				var offset = perpendicular * randf_range(-25, 25)
				panic_locations.push_back(point_on_line + offset)

func run_state(delta, state):
	match state:
		WORKING:
			if nav.is_navigation_finished() && $ActionComplete.is_stopped():
				$ActionComplete.start()
				#$AnimationPlayer.play(job_type)
		IDLING:
			if nav.is_navigation_finished():
				nav.target_position = Vector2(randf_range(-200, 200), randf_range(-200, 200)) + global_position
		SCARED:
			# Run around panicking
			# Enter house when reached
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
	if job_points == require_job_points:
		job_complete()
		job_points = 0
