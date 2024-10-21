extends Node2D

func _ready():
	set_emote("none")

func set_emote(id : String):
	if id == "none":
		$Sprite2D.visible = false
	else:
		$Sprite2D.visible = true
		$AnimationPlayer.play(id)
