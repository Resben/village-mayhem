extends Control

func _on_continue_pressed():
	get_parent().toggle_pause()

func _on_to_menu_pressed():
	get_parent().switch_to_menu()

func when_shown():
	$TextureRect/HSlider.value = get_parent().bgm_volume
