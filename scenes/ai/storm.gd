extends Area2D

var velocity
var direction
var destroyables_in_area = []

var playback_speed = 1
var original_wait_time = 0.25

func _ready():
	playback_speed = Global.hud.current_playback
	$Sprite2D.speed_scale = playback_speed
	Global.disaster_references.push_back(self)
	$DamageTick.wait_time =  original_wait_time / playback_speed

func _physics_process(delta):
	global_position += direction * 50 * delta * playback_speed

func _on_area_entered(area):
	if area is HitBox:
		destroyables_in_area.push_back(area)
		area.get_parent().set_wind(true)
	if area is VillagerTag:
		Global.controller.restart_disaster_timer()

func _on_area_exited(area):
	if area is HitBox:
		destroyables_in_area.erase(area)
		area.get_parent().set_wind(false)

func _on_damage_tick_timeout():
	for h in destroyables_in_area:
		h.take_damage()
	
	$DamageTick.start()

func set_speed(value):
	playback_speed = value
	$Sprite2D.speed_scale = value
	$DamageTick.wait_time =  original_wait_time / value

func _on_time_on_screen_timeout():
	Global.disaster_references.erase(self)
	queue_free()
