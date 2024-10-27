extends Control

var ui_shown = false
var current_selection = -1
@onready var ui_rect = $Control.get_global_rect()

var playback_id = 1

@export var playback_1 : Texture2D
@export var playback_2 : Texture2D
@export var playback_3 : Texture2D

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

func _on_animation_player_finished(_anim_name):
	$AnimationPlayer.play("idle")

func _on_item_clicked(index, _at_position, _mouse_button_index):
	if current_selection == index:
		deselect()
	else:
		current_selection = index

func deselect():
	$Control/TextureRect2/ItemList.deselect_all()
	current_selection = -1

func _on_playback_pressed():
	playback_id += 1
	if playback_id == 4:
		playback_id = 1
	match playback_id:
		1:
			Global.set_game_speed(Global.NORMAL)
			$Playback.texture_normal = playback_1
		2:
			Global.set_game_speed(Global.FAST)
			$Playback.texture_normal = playback_2
		3:
			Global.set_game_speed(Global.VERY_FAST)
			$Playback.texture_normal = playback_3
