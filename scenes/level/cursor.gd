extends AnimatedSprite2D

@export var village_map : TileMap

func _physics_process(delta):
	global_position = get_world_pos_tile(get_global_mouse_position() + Vector2(8, 8))
	
func get_world_pos_tile(world_pos):
	var x = floori(world_pos.x / 16) * 16
	var y = floori(world_pos.y / 16) * 16
	return Vector2(x, y)

func _input(event):
	if Input.is_action_just_pressed("left_mouse"):
		village_map.check_availablity(position)
