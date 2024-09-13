extends Control

var ui_shown = false

func _ready():
	Global.hud = self
	$Control/TextureButton.flip_h = true
	$Control.position.x = 640

func update_population():
	$Control/Population.text = str(Global.population)

func update_resources():
	$Control/Food.text = str(Global.resources["food"])
	$Control/Materials.text = str(Global.resources["materials"])
	$Control/Wood.text = str(Global.resources["wood"])

func _on_show_ui_pressed():
	if ui_shown:
		$AnimationPlayer.play("hide_ui")
		ui_shown = false
	else:
		$AnimationPlayer.play("show_ui")
		ui_shown = true

func _on_animation_player_finished(anim_name):
	$AnimationPlayer.play("idle")
