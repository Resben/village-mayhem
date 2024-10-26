extends Area2D
class_name HitBoxComponent

@export var tick_damage : int
@export var should_tick_damage : bool
@export var tick_interval : float

@export var impact_damage : int
@export var should_impact_damage : bool

@export var hit_type : String # Later this can be a data object which provides additional hit information

var hurtboxes = []
var original_tick_interval

func _ready():
	self.collision_layer = 8
	self.collision_mask = 16
	Global.connect("_on_speed_changed", _speed_changed)
	original_tick_interval = tick_interval
	
	_speed_changed(Global.hud.current_playback)
	
	if tick_interval && should_tick_damage:
		$Timer.start()

func _on_area_entered(area):
	if should_impact_damage:
		area.apply_impact_damage(impact_damage, hit_type)
	elif should_tick_damage:
		hurtboxes.push_back(area)
	
	#### TEMPORARY
	if area is VillagerTag:
		Global.controller.restart_disaster_timer()

func _on_area_exited(area):
	if should_tick_damage:
		hurtboxes.erase(area)

func _on_timer_timeout():
	$Timer.start()
	for h in hurtboxes:
		h.apply_tick_damage(tick_damage, hit_type)

func _speed_changed(speed : float):
	if tick_interval && should_tick_damage:
		$Timer.wait_time = original_tick_interval / speed
