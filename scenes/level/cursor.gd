extends AnimatedSprite2D

@export var village_map : TileMap
@export var cpu : CPU

var first_point = null
var second_point = null

func _physics_process(delta):
	global_position = get_world_pos_tile(get_global_mouse_position() + Vector2(16, 16))
	
func get_world_pos_tile(world_pos):
	var x = floori(world_pos.x / 32) * 32
	var y = floori(world_pos.y / 32) * 32
	return Vector2(x, y)

func _unhandled_input(event):
	if Global.hud.current_selection != -1:
		if Input.is_action_just_pressed("left_mouse"):
			if first_point == null:
				first_point = get_global_mouse_position()
			elif second_point == null && first_point != get_global_mouse_position():
				second_point = get_global_mouse_position()
			
			if first_point != null && second_point != null:
				Global.disaster_controller.place_storm(first_point, second_point)
				first_point = null
				second_point = null
				Global.hud.deselect()
