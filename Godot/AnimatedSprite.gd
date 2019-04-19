extends AnimatedSprite

func animateDeath():
	print("animation started!")
	self.animation = "DeathFade"
	self.playing = true


func _on_animation_finished():
	print("animation finished!")
	emit_signal("animation_finished")
