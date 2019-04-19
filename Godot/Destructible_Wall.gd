extends StaticBody2D

export var HEALTH = 200

func takeDamage(damage):
	HEALTH -= damage
	if HEALTH <= 0:
		onDeath()
		self.queue_free()

func onDeath():
	pass #Fancy particle animation

func onProjectileHit(damage):
	takeDamage(damage)