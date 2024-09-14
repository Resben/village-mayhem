extends Node2D

var storm = preload("res://scenes/ai/storm.tscn")

@export var camera : Camera2D

func _ready():
	Global.disaster_controller = self

func place_storm(start, end):
	var scene = storm.instantiate()
	var camera_limits = Rect2(Vector2(camera.limit_left, camera.limit_top), Vector2(camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top))
	
	var direction = (end - start).normalized()
	var start_position = start
	
	while(camera_limits.has_point(start_position)):
		start_position += -direction * 10

	# Set the object's position and direction
	scene.position = start_position
	scene.direction = direction
	add_child(scene)
