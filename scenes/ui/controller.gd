extends CanvasLayer
class_name Controller

enum { MENU, PAUSED, GAME }

var state = MENU

var current_bgm = "peaceful"
var bgm_volume = 1.0
var sfx_volume = 1.0

var disaster_time_out_original = 9

# Called when the node enters the scene tree for the first time.
func _ready():
	$Startup.visible = true
	$HUD.visible = false
	$Paused.visible = false
	get_tree().paused = true
	Global.controller = self

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

func switch_bgm(id):
	if id == current_bgm:
		return
	
	current_bgm = id
	var tween = get_tree().create_tween()
	tween.tween_property($BGM, "volume_db", linear_to_db(0.0), 7.5)
	tween.tween_callback(next_track)

func next_track():
	if current_bgm == "peaceful":
		pass #$BGM.play("peaceful")
	else:
		pass #BGM.play("chaos")
	
	var tween = get_tree().create_tween()
	tween.tween_property($BGM, "volume_db", linear_to_db(bgm_volume), 7.5)

func play_SFX(id):
	pass

func restart_disaster_timer():
	if !Global.is_in_disaster:
		switch_bgm("chaos")
		on_disaster()
	
	$DisasterTimer.start()

func on_disaster():
	Global.is_in_disaster = true
	for v in Global.villager_references:
		v.on_disaster()

func disaster_over():
	Global.is_in_disaster = false
	for v in Global.villager_references:
		v.disaster_over()

func _on_disaster_timer_timeout():
	disaster_over()
	switch_bgm("peaceful")

func set_speed(value):
	$DisasterTimer.wait_time = disaster_time_out_original / value
