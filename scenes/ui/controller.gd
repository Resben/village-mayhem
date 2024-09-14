extends CanvasLayer
class_name Controller

enum { MENU, PAUSED, GAME }

var state = MENU

# Called when the node enters the scene tree for the first time.
func _ready():
	$Startup.visible = true
	$HUD.visible = false
	$Paused.visible = false
	get_tree().paused = true

func _input(event):
	if Input.is_action_just_pressed("pause") && !$Startup.visible:
		$Paused.visible = !$Paused.visible
		if $Paused.visible:
			$Paused.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			$Paused.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_tree().paused = $Paused.visible

func switch_to_game():
	state = GAME
	$TransitionPlayer.play_transition(to_game_callback)

func to_game_callback():
	$Startup.visible = false
	$Startup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.visible = true
	get_tree().paused = false

