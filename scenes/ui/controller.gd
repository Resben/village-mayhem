extends CanvasLayer
class_name Controller

enum { MENU, PAUSED, GAME }

var state = MENU

# Called when the node enters the scene tree for the first time.
func _ready():
	$Startup.visible = true
	$HUD.visible = false
	$Paused.visible = false

func _input(event):
	if Input.is_action_just_pressed("pause") && !$Startup.visible:
		$Paused.visible = !$Paused.visible
		get_tree().paused = $Paused.visible

func switch_to_game():
	state = GAME
	$TransitionPlayer.play_transition(to_game_callback)

func to_game_callback():
	$Startup.visible = false
	$HUD.visible = true
