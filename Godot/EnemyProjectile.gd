extends KinematicBody2D

export var PROJECTILE_SPEED = 200
var movementVector = false
var damage

func _physics_process(delta):
	if movementVector:
		var collisionObject = move_and_collide(movementVector * delta)
		if collisionObject != null:
			self.queue_free() #Delete this node and its children at the end of the frame
			if collisionObject.get_collider().has_method("onProjectileHit"):
				collisionObject.get_collider().onProjectileHit(damage)

func shoot(startPos, normalizedDirectionVector, damage):
	self.damage = damage
	movementVector = normalizedDirectionVector * PROJECTILE_SPEED
	self.position = startPos