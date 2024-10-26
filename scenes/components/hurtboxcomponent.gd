extends Area2D
class_name HurtBoxComponent

signal _on_damage
signal _on_tick_damage
signal _on_impact_damage

@export var health_component : HealthComponent
@export var process_tick_damage : bool
@export var process_impact_damage : bool

func _ready():
	self.collision_layer = 16
	self.collision_mask = 0

func apply_impact_damage(dmg, type = null):
	if health_component && process_impact_damage:
		health_component.damage(dmg)
	
	_on_damage.emit(dmg, type)
	_on_impact_damage.emit(dmg, type)

func apply_tick_damage(dmg, type = null):
	if health_component && process_tick_damage:
		health_component.damage(dmg)
	
	_on_damage.emit(dmg, type)
	_on_tick_damage.emit(dmg, type)
