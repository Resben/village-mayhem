extends CharacterBody2D
class_name Villager

@onready var nav = $NavigationAgent2D
var direction
var texture : Texture2D

func _ready():
	$Sprite2D.texture = Global.get_random_villager()

func go_to(pos):
	nav.target_position = pos

func _physics_process(delta):
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
