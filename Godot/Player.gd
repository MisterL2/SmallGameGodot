extends KinematicBody2D

export var SPEED = 120
export var RELOAD_TIME = 0.2
export var DAMAGE = 100
export var HEALTH = 1000
export var MAX_HEALTH = 1000

const NORMAL_PROJECTILE = preload("Player_Projectile.tscn")
const STRONGER_PROJECTILE = preload("Stronger_Player_Projectile.tscn")

var ACTIVE_PROJECTILE

onready var PlayerModel = $PlayerModel
onready var PlayerHitbox = $PlayerHitbox
onready var GUI = $"../GUI"

var playerMotion = Vector2()

var timeSinceLastShot = 10 #Able to shoot right away

const INTERACTION_COOLDOWN = 0.2
var timeSinceLastInteraction = 1 #Able to react right away

var move_disabled_time = 0
var alive = true

var nearbyItem #When an item is on the ground near the player. Usually null
var equippedItem #The one special item that is equipped. Usually null
var activeBuffs = {}
var keys = 0

var pickedName = 'Player' #Player-chosen name, can be used later for dialog. DO NOT try to use the field "name", as it will break other scripts which type-check the player this way!

var difficulty = 'Easy' #Derived from base regularly

enum Layer {ENVIRONMENT = 1, PLAYER = 2, ENEMY = 4, ITEM = 512, FRIENDLY_ENVIMMUNE_PROJECTILE = 1024, FRIENDLY_PROJECTILE = 2048, ENEMY_PROJECTILE = 4096, ENEMY_ENVIMMUNE_PROJECTILE = 8192, INTERACTABLE = 524288}
const difficulties = {'Easy':1, 'Medium':0.75, 'Hard':0.5}

func _ready():
	print("PLAYER READY!")
	ACTIVE_PROJECTILE = NORMAL_PROJECTILE
	if $"/root/Base".gameState == 'Active':
		difficulty = $"/root/Base".DIFFICULTY #Prevents the difficulty modifier from reducing health when switching scenes

func on_difficulty_change(newDifficulty):
	print("Player difficulty changed!")
	var modifier = difficulties[newDifficulty] / difficulties[self.difficulty]
	self.difficulty = newDifficulty
	
	DAMAGE *= modifier
	MAX_HEALTH *= modifier
	HEALTH *= modifier
	onHealthChange()

func _process(delta):
	if nearbyItem != null and Input.is_action_just_pressed("ui_pickup_item"):
		if nearbyItem.type == 'Equipment':
			if equippedItem != null:
				dropItem(equippedItem)
		nearbyItem.pickup(self)

func onHealthChange(change=0): #Negative value for damage
	print("Health change " + str(change))
	GUI.updateMaxHealth(MAX_HEALTH)
	GUI.updateCurrentHealth(max(HEALTH,0))

func set_health(health=HEALTH,max_health=MAX_HEALTH):
	HEALTH = health
	MAX_HEALTH = max_health
	onHealthChange()

func turn(angle):
		PlayerModel.rotation = angle
		PlayerHitbox.rotation = angle

func onPlayerDeath():
	alive = false #Prevents player from acting during the death animation
	$"/root/Base".onPlayerDeath()
	self.queue_free()
	#Play death animation / "You lose" screen
	print("YOU DIED!")

func takeDamage(damage):
	if not alive:
		return
	#Add special functionality here later
	HEALTH -= damage
	onHealthChange(-damage)
	if HEALTH <= 0:
		onPlayerDeath()

func gainHealth(healthGain):
	if not alive:
		return
	#Add special functionality here
	healthGain *= difficulties[difficulty] #less healthgain on higher difficulty
	HEALTH = min(HEALTH+healthGain,MAX_HEALTH)
	onHealthChange(healthGain)

func calculate_player_movement():
	if Input.is_action_pressed("ui_left"):
		playerMotion.x = -1
	elif Input.is_action_pressed("ui_right"):
		playerMotion.x = 1
	else:
		playerMotion.x = 0
		
	if Input.is_action_pressed("ui_up"):
		playerMotion.y = -1
	elif Input.is_action_pressed("ui_down"):
		playerMotion.y = 1
	else:
		playerMotion.y = 0
		
	#Decrease diagonal speed
	if abs(playerMotion.y) + abs(playerMotion.x) == 2:
		playerMotion /= sqrt(2)
	
	#Apply speed value
	playerMotion *= SPEED

func shoot(targetVector):
	var x = self.position.x
	var y = self.position.y
	
	targetVector.x -= x
	targetVector.y -= y
	
	var bullet_damage = DAMAGE
	var amountOfBullets = 1
	if "TripleShoot" in activeBuffs:
		amountOfBullets *=3
		use_buff("TripleShoot")
	
	if "DamageUp" in activeBuffs:
		use_buff("DamageUp")
		ACTIVE_PROJECTILE = STRONGER_PROJECTILE
		bullet_damage *= 1.5
	else:
		ACTIVE_PROJECTILE = NORMAL_PROJECTILE
	
	for i in range(amountOfBullets):
		var normalizedTargetVector = targetVector.rotated((i - floor(amountOfBullets/2)) * PI / 12).normalized()
		var startPos = Vector2(x,y) + normalizedTargetVector * 15
		var current = ACTIVE_PROJECTILE.instance()
		get_parent().add_child(current)
		current.shoot(startPos, normalizedTargetVector, bullet_damage)
		timeSinceLastShot = 0

func _input(event):
	if not alive:
		return
	if event is InputEventMouseMotion:
		turn((get_viewport().get_mouse_position() - self.position).angle())

func use_buff(buffName):
	activeBuffs[buffName] -= 1
	if activeBuffs[buffName] == 0:
		activeBuffs.erase(buffName)

func _physics_process(delta):
	if self.difficulty != $"/root/Base".DIFFICULTY:
		self.on_difficulty_change($"/root/Base".DIFFICULTY)
	if not alive:
		return
	timeSinceLastShot += delta
	timeSinceLastInteraction += delta
	if Input.is_action_pressed("ui_shoot") and timeSinceLastShot > RELOAD_TIME:
		shoot(get_viewport().get_mouse_position())
	elif Input.is_action_just_pressed("ui_interact"):
		interact(findNearestInteractable())
	if move_disabled_time > 0:
		move_disabled_time -= delta
	else:
		calculate_player_movement()
	#GDScript does not support kwargs, so i have to supply all the other parameters to set infinite_inertia to false
	move_and_slide(playerMotion,Vector2( 0, 0 ),false,4,0.785398,false) #Calculated either way, but if move_disabled_time is on, the user inputs are ignored
	
func onProjectileHit(damage,bodypart=null):
	#print("You were hit for %d damage!" % damage)
	takeDamage(damage)
	#print("Your HP: %d / 1000" % HEALTH)
	
func onFindItem(item):
	self.nearbyItem = item
	
func onLeaveItem(item):
	if self.nearbyItem == item:
		self.nearbyItem = null
		
func dropItem(itemToBeDropped):
	pass #Fancy dropping animation, spawn entity back or something

func onKeyPickup(keyType):
	print("Picked up key!")
	if keyType == "Regular":
		keys += 1
	else:
		print("Unexpected keytype in onKeyPickup in Player! TBD!")

func interact(nearestInteractable):
	if nearestInteractable != null and timeSinceLastInteraction > INTERACTION_COOLDOWN: #If there is something to interact
		nearestInteractable.interact(self)
		timeSinceLastInteraction = 0

func findNearestInteractable(): #Finds the first interactable that is within 15px of the direction that the player is facing. Might return an empty dictionary.
	var collision_result = get_world_2d().direct_space_state.intersect_ray(position,position + (get_viewport().get_mouse_position()-position).normalized()*30,[self], Layer.INTERACTABLE)
	if not collision_result:
		return null
	else:
		return collision_result.collider