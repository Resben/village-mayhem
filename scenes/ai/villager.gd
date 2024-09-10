extends CharacterBody2D
class_name Villager

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

func return_to_house():
	nav.target_position = house.door_pos
	is_returning = true

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
			var task = find_best_slot(Global.farm_references)
			if task != null:
				nav.target_position = task.global_position
				task.add_worker()
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
	if in_house:
		return
	
	if nav.is_navigation_finished():
		if is_returning && !in_house:
			enter_house()
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
