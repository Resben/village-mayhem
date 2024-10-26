extends Node2D

@onready var velocity_component : VelocityComponent = $VelocityComponent

var direction

func _ready():
	Global.connect("_on_speed_changed", _speed_changed)
	_speed_changed(Global.hud.current_playback)
	Global.disaster_references.push_back(self)

func _physics_process(delta):
	velocity_component.accelerate_in_direction(direction)
	velocity_component.move_body(self, delta)

func _on_time_on_screen_timeout():
	Global.disaster_references.erase(self)
	queue_free()

func _speed_changed(value : float):
	$Sprite2D.speed_scale = value
	print($Sprite2D.speed_scale)
