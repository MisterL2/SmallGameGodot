extends AnimatedSprite

func animateDeath():
	self.animation = "DeathFade"
	self.playing = true


func _on_animation_finished(): # Never called apparently?
	emit_signal("animation_finished")
