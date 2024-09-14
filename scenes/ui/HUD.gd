extends Control

var ui_shown = false
var current_selection = -1
@onready var ui_rect = $Control.get_global_rect()

func _ready():
	$Control/TextureRect2/ItemList.set_item_tooltip_enabled(0, false)
	
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

func _on_item_clicked(index, at_position, mouse_button_index):
	if current_selection == index:
		deselect()
	else:
		current_selection = index

func deselect():
	$Control/TextureRect2/ItemList.deselect_all()
	current_selection = -1
