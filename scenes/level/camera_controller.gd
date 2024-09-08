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
		position = (mouse_start_pos - event.position) + screen_start_pos
	
	if event.is_action("zoom_in"):
		if zoom.x < 3:
			zoom += Vector2(0.1, 0.1)
	if event.is_action("zoom_out"):
		if zoom.x > 0.5:
			zoom -= Vector2(0.1, 0.1)
		
