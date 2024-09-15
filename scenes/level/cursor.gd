extends AnimatedSprite2D

@export var village_map : TileMap
@export var cpu : CPU

var waypoint = preload("res://scenes/ui/waypoint.tscn")

var first_point = null
var second_point = null

var first_waypoint
var second_waypoint

func _physics_process(delta):
	global_position = get_world_pos_tile(get_global_mouse_position() + Vector2(16, 16))
	
func get_world_pos_tile(world_pos):
	var x = floori(world_pos.x / 32) * 32
	var y = floori(world_pos.y / 32) * 32
	return Vector2(x, y)

func _unhandled_input(event):
	
	#if Input.is_action_just_pressed("left_mouse"):
		#Global.on_disaster()
	#if Input.is_action_just_pressed("right_mouse"):
		#Global.disaster_over()
	
	if Global.hud.current_selection != -1:
		
		if first_point == null && second_point == null:
			play("first")
		elif first_point != null && second_point == null:
			play("second")
		
		if Input.is_action_just_pressed("left_mouse"):
			if first_point == null:
				first_point = get_global_mouse_position()
				first_waypoint = waypoint.instantiate()
				first_waypoint.global_position = global_position
				first_waypoint.id = "first"
				get_parent().add_child(first_waypoint)
			elif second_point == null && first_point != get_global_mouse_position():
				second_point = get_global_mouse_position()
				second_waypoint = waypoint.instantiate()
				second_waypoint.global_position = global_position
				second_waypoint.id = "second"
				get_parent().add_child(second_waypoint)
			
			if first_point != null && second_point != null:
				Global.disaster_controller.place_storm(first_point, second_point)
				first_point = null
				second_point = null
				Global.hud.deselect()
				$WaypointTimer.start()
				play("default")


func _on_waypoint_timer_timeout():
	first_waypoint.queue_free()
	second_waypoint.queue_free()
