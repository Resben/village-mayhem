extends Node2D
class_name NavigationComponent

@export var velocity_component : VelocityComponent

func _ready():
	$NavigationAgent2D.connect("velocity_computed", _on_velocity_computed)

func get_target_position():
	return $NavigationAgent2D.target_position

func set_layer(layer : int):
	$NavigationAgent2D.navigation_layers = layer

func set_target_position(target_position : Vector2):
	if !$IntervalTimer.is_stopped():
		return
	
	$IntervalTimer.call("start")
	$NavigationAgent2D.target_position = target_position

func force_set_target_position(target_position : Vector2):
	$NavigationAgent2D.target_position = target_position
	$IntervalTimer.call("start")

func follow_path():
	if $NavigationAgent2D.is_navigation_finished():
		velocity_component.decelerate()
		return
	var direction = ($NavigationAgent2D.get_next_path_position() - global_position).normalized()
	velocity_component.accelerate_in_direction(direction)
	$NavigationAgent2D.velocity = velocity_component.velocity

func _on_velocity_computed(velocity : Vector2):
	var newDirection = velocity.normalized()
	var currentDirection = velocity_component.velocity.normalized()
	var halfway = newDirection.lerp(currentDirection, 1.0 - exp(velocity_component.accelaration_coefficient * velocity_component.game_speed_multiplier))
	velocity_component.velocity = halfway * velocity_component.velocity.length()

func is_navigation_possible(target_position):
	var current_path = $NavigationAgent2D.target_position
	$NavigationAgent2D.target_position = target_position
	var final_position = $NavigationAgent2D.get_final_position()
	if final_position != null && final_position.distance_to(target_position) < 5:
		$NavigationAgent2D.target_position = current_path
		return true
	$NavigationAgent2D.target_position = current_path
	return false

func is_navigation_finished():
	return $NavigationAgent2D.is_navigation_finished()

func get_navigation_target():
	return $NavigationAgent2D.target_position
