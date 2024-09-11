extends Control

func _ready():
	Global.hud = self

func update_population():
	$Population.text = str(Global.population)

func update_resources():
	$Food.text = str(Global.resources["food"])
