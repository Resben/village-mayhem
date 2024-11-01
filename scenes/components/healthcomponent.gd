extends Node
class_name HealthComponent

signal _on_health_change # Emit when health changes
signal _on_health_depletion # Emit when health depletes
signal _on_max_health # Emit when health reaches max

@export var max_health : int = 10
var current_health : int
var last_health : int
var health_percentage : float

func _ready():
	current_health = max_health

func damage(dmg):
	last_health = current_health
	current_health -= dmg
	current_health = min(current_health, max_health)
	
	health_percentage = (current_health / max_health) * 100
	_on_health_change.emit()
	
	if current_health <= 0:
		_on_health_depletion.emit()
		current_health = 0

func heal(health):
	if current_health != max_health:
		damage(-health)
		if current_health == max_health:
			_on_max_health.emit()

func has_max_health() -> bool:
	return true if current_health == max_health else false

func has_no_health() -> bool:
	return true if current_health <= 0 else false

func get_health_as_percentage() -> float:
	if current_health == 0:
		return 0.0
	return float(min(current_health, max_health)) / max_health
