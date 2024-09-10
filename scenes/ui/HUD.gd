extends Control

func _ready():
	Global.hud = self

func update_population():
	$Population.text = str(Global.population)
