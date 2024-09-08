extends Control

@export var main : PackedScene

func _on_button_pressed():
	if get_parent().state == Controller.MENU:
		var next = main.instantiate()
		get_node("/root/").add_child(next)
		get_parent().switch_to_game()
