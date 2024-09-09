extends CharacterBody2D
class_name Villager

@onready var nav = $NavigationAgent2D
var direction
var texture : Texture2D
var house : House

var in_house = false
var is_returning = false

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
