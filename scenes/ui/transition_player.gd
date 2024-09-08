extends Control

var next_callback : Callable

func play_transition(callback : Callable):
	next_callback = callback
	$AnimationPlayer.play("transition")

func play_callback():
	next_callback.call()
