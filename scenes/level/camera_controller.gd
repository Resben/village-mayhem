extends Camera2D

var mouse_start_pos
var screen_start_pos
var dragging = false

func _input(event):
	if event.is_action("drag"):
		if event.is_pressed():
			mouse_start_pos = event.position
			screen_start_pos = position
			dragging = true
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = ((mouse_start_pos - event.position) * (1.0 / zoom.x)) + screen_start_pos
		
	
	if event.is_action("zoom_in"):
		if zoom.x < 3:
			zoom += Vector2(0.025, 0.025)
	if event.is_action("zoom_out"):
		if zoom.x > 0.2:
			zoom -= Vector2(0.025, 0.025)

func set_limits():
	Global.map_size
