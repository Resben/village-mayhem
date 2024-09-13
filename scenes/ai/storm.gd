extends Area2D

var velocity
var target = Vector2(1060, 650)
var destroyables_in_area = []

func _physics_process(delta):
	if global_position.distance_to(target) < 3:
		#AnimationPlayer.play("fade_out")
		queue_free()
		pass
	
	global_position += global_position.direction_to(target) * 100 * delta
	

func _on_area_entered(area):
	if area is HitBox:
		destroyables_in_area.push_back(area)

func _on_area_exited(area):
	if area is HitBox:
		destroyables_in_area.erase(area)

func _on_damage_tick_timeout():
	for h in destroyables_in_area:
		h.take_damage()
	
	$DamageTick.start()
