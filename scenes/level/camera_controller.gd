extends Camera2D

var mouse_start_pos
var screen_start_pos
var dragging = false

func _ready():
	limit_left = 0
	limit_top = 0
	limit_right = Global.map_size.x * 32
	limit_bottom = Global.map_size.y * 32

func _input(event):
	if event.is_action("drag"):
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_pos = position
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		var screen_size = get_viewport().get_size()
		var mouse_pos = event.position
		
		if mouse_pos.x >= 0 and mouse_pos.x <= screen_size.x and mouse_pos.y >= 0 and mouse_pos.y <= screen_size.y:
			position = ((mouse_start_pos - mouse_pos) * (1.0 / zoom.x)) + screen_start_pos

	
	if event.is_action("zoom_in"):
		if zoom.x < 3:
			zoom += Vector2(0.025, 0.025)
		if zoom.x > 3:
			zoom = Vector2(3.0, 3.0)
	if event.is_action("zoom_out"):
		if zoom.x > 0.2:
			zoom -= Vector2(0.025, 0.025)
		if zoom.x < 0.2:
			zoom = Vector2(0.2, 0.2)
