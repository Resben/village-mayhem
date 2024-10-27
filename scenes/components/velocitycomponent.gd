extends Node
class_name VelocityComponent

@export var max_speed : float = 100;
@export var accelaration_coefficient : float = 10;

@onready var game_speed_multiplier : float = Global.current_playback

var velocity : Vector2
var velocity_override : Vector2

var speed_percent_modifiers = {}

func _ready():
	Global.connect("_on_speed_changed", _speed_changed)
	_speed_changed(Global.current_playback)

func calculate_max_speed():
	return max_speed * (1.0 + 0.0) * game_speed_multiplier # Replace 0.0 with speed modifiers when we actually use them

func get_speed_percent():
	var max_speed_value = calculate_max_speed()
	
	if max_speed_value > 0.0:
		return min(velocity.length() / max_speed_value, 1.0)
	else:
		return min(velocity.length() / 1.0, 1.0)

func accelerate_to_velocity(vel : Vector2):
	velocity = velocity.lerp(vel, 1.0 - exp(-accelaration_coefficient * game_speed_multiplier))

func accelerate_in_direction(dir : Vector2):
	accelerate_to_velocity(dir * calculate_max_speed())

func get_max_velocity(dir):
	return dir * calculate_max_speed()

func maximise_velocity(dir : Vector2):
	velocity = get_max_velocity(dir)

func decelerate():
	accelerate_to_velocity(Vector2.ZERO)

func move(characterBody : CharacterBody2D):
	#characterBody.velocity = velocity_override if velocity_override != null else velocity
	characterBody.velocity = velocity
	characterBody.move_and_slide()

func move_body(node : Node2D, delta : float):
	node.position += velocity * delta

func set_max_speed(new_speed : float):
	max_speed = new_speed

func set_speed_percentage_modifier(id : String, val : float):
	speed_percent_modifiers[id] = val

func get_speed_percentage_modifier(id : String):
	if speed_percent_modifiers.has(id):
		return speed_percent_modifiers[id]
	else:
		return null

func _speed_changed(value : float):
	game_speed_multiplier = value
