extends KinematicBody2D

export var RELOAD_TIME = 0.5
export var DAMAGE = 100
export var HEALTH = 400
export var MAX_HEALTH = 400

const Projectile = preload("Enemy_Projectile.tscn")

var alive = true
var timeSinceLastShot = 0

export var SPEED = 100


enum Layer {ENVIRONMENT = 1, PLAYER = 2, ENEMY = 4, FRIENDLY_ENVIMMUNE_PROJECTILE = 1024, FRIENDLY_PROJECTILE = 2048, ENEMY_PROJECTILE = 4096, ENEMY_EVNIMMUNE_PROJECTILE = 8192}


#const standardVectors = [Vector2(0,1),Vector2(0,-1),Vector2(1,0),Vector2(1,1),Vector2(1,-1),Vector2(-1,1),Vector2(-1,0),Vector2(-1,-1)]
const standardVectors = [Vector2(0,-1),Vector2(0,1),Vector2(-1,0),Vector2(1,0)]


var surroundingWalls = [] # Left, Right, Up, Down (order determiend by standardVectors const)

var directionVector = Vector2()
var extents
var framesTillPlannedMove = -1
var plannedMove = Vector2()
var directionChange = false


func _ready():
	$HealthBar.max_value = MAX_HEALTH
	$HealthBar.value = HEALTH	
	$AnimatedSprite.connect("animation_finished",self,"death_complete")
	directionVector = standardVectors[randi() % standardVectors.size()]
	var collisionShape = $CollisionShape2D.shape
	if collisionShape.is_class("CircleShape2D"):
		extents = collisionShape.radius
	else:
		extents = collisionShape.extents.length() # UNTESTED, for rectangle shapes!
	surroundingWalls = calculate_surrounding_walls()
	
	
func onDeath():
	alive = false
	$CollisionShape2D.queue_free() #No more collisions
	$AnimatedSprite.animateDeath()
	
func death_complete():
	self.queue_free()
	
func takeDamage(damage): 
	#Add special functionality here later
	HEALTH -= damage
	$HealthBar.value = max(HEALTH,0)
	if HEALTH <= 0:
		onDeath()
		
func onProjectileHit(damage):
	#print("Enemy hit for %d damage!" % damage)
	takeDamage(damage)
	#print("Enemy HP: %d / 400" % HEALTH)
	
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
	if not alive:
		return
	timeSinceLastShot += delta
	if canSeePlayer(playerPos):
		follow_player(playerPos) #Modifies directionVector
		if timeSinceLastShot > RELOAD_TIME:
			shoot(playerPos)
	else:
		base_movement(20) #Modifies directionVector
	rotation = directionVector.angle()
	move_and_slide(directionVector * SPEED) #Executes movement
	if directionChange:
		surroundingWalls = calculate_surrounding_walls()
		directionChange = false
		


func canSeePlayer(playerPos):
		var surroundings = get_world_2d().direct_space_state
		var result = surroundings.intersect_ray(position,playerPos, [self], Layer.ENVIRONMENT + Layer.PLAYER + Layer.ENEMY)
		return result and result.collider.name == "Player"


func base_movement(tolerance):
	if framesTillPlannedMove == 0:
		directionVector = plannedMove
		directionChange = true
	if framesTillPlannedMove >= 0:
		framesTillPlannedMove-=1
	else:
		maybeTurn()
		
	if path_blocked(directionVector,20):
		var possible_directions = []
		for vector in standardVectors:
			if not path_blocked(vector,tolerance):
				possible_directions.append(vector)
		if not possible_directions:
			print("Recursion warning!")
			base_movement(tolerance*0.9)
		else:
			directionVector = possible_directions[randi()%possible_directions.size()]
			directionChange = true

func path_blocked(direction,distance):
	return get_world_2d().direct_space_state.intersect_ray(position,position + direction * distance , [self], Layer.ENVIRONMENT + Layer.ENEMY)
	#return rayCast(space,direction*distance,Vector2()) or rayCast(space,direction*distance,Vector2(-extents,0)) or rayCast(space,direction*distance,Vector2(0,-extents-2)) or rayCast(space,direction*distance,Vector2(extents+2,0)) or rayCast(space,direction*distance,Vector2(0,extents+2))
	
#func rayCast(space, directionDistance, startPosMod):
#	return space.intersect_ray(position + startPosMod,position + directionDistance , [self], Layer.ENVIRONMENT + Layer.ENEMY)
	
func follow_player(playerPos):
	var vectorDifference = playerPos - position
	directionVector = vectorDifference.normalized()
	if vectorDifference.length() < 100:
		directionVector /= 100 #Almost no movement, but keeps facing the right direction
	
func calculate_surrounding_walls():
	var new_surrounding_walls = []
	for vector in standardVectors:
		if path_blocked(vector,20):
			new_surrounding_walls.append(vector)
		else:
			new_surrounding_walls.append(null)
	return new_surrounding_walls
	
func maybeTurn():
	var new_surrounding_walls = calculate_surrounding_walls()
	for i in range(4):
		if new_surrounding_walls[i] != surroundingWalls[i]:
			if not new_surrounding_walls[i]: #Previous wall ended
				if randi()%2 == 0: #50% Chance to turn to a new opening
					plannedMove = surroundingWalls[i] #surroundingWalls[i] has the direction, whereas new_surrounding_walls has value "false" instead
					surroundingWalls = new_surrounding_walls
					framesTillPlannedMove = 8
	surroundingWalls = new_surrounding_walls