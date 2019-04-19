extends Node

export var RELOAD_TIME = 0.5
export var DAMAGE = 100
export var HEALTH = 400
export var MAX_HEALTH = 400
export var position = Vector2()

const Projectile = preload("Enemy_Projectile.tscn")

var alive = true
var timeSinceLastShot = 0



func _ready():
	$HealthBar.value = HEALTH
	$HealthBar.max_value = MAX_HEALTH
	$Body.position = position
	
	
func onDeath():
	alive = false
	$Body/CollisionShape2D.queue_free() #No more collisions
	$Body/AnimatedSprite.animateDeath()
	
func death_complete():
	self.queue_free()
	
func takeDamage(damage): 
	#Add special functionality here later
	HEALTH -= damage
	$HealthBar.value = max(HEALTH,0)
	if HEALTH <= 0:
		onDeath()
		
func onProjectileHit(damage):
	print("Enemy hit for %d damage!" % damage)
	takeDamage(damage)
	print("Enemy HP: %d / 400" % HEALTH)
	
func shoot(targetVector):
	var x = self.position.x
	var y = self.position.y

	targetVector.x -= x
	targetVector.y -= y
	
	var normalizedTargetVector = targetVector.normalized()
	var startPos = Vector2(x,y) + normalizedTargetVector * 20
	var current = Projectile.instance()
	get_parent().add_child(current)
	current.shoot(startPos, normalizedTargetVector, DAMAGE)
	timeSinceLastShot = 0
	
func maybeShoot(delta,playerPos): #Called EVERY PHYSICS PROCESS from Warehouse-Node
	timeSinceLastShot += delta
	if $Body.movement_logic(playerPos):		
		if timeSinceLastShot > RELOAD_TIME:
			shoot(playerPos)