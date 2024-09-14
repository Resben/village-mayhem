extends Area2D

var velocity
var direction
var destroyables_in_area = []

func _physics_process(delta):
	global_position += direction * 100 * delta

func _on_area_entered(area):
	if area is HitBox:
		destroyables_in_area.push_back(area)
		area.get_parent().is_windy()

func _on_area_exited(area):
	if area is HitBox:
		destroyables_in_area.erase(area)
		area.get_parent().not_windy()

func _on_damage_tick_timeout():
	for h in destroyables_in_area:
		h.take_damage()
	
	$DamageTick.start()
