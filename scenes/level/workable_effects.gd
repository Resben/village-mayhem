extends Sprite2D

func play_anim(id):
	if id:
		$AnimationPlayer.play(id)
