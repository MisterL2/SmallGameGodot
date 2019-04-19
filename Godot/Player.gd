extends KinematicBody2D

export var SPEED = 120
export var RELOAD_TIME = 0.15
export var DAMAGE = 50
export var HEALTH = 500
export var MAX_HEALTH = 500

const NORMAL_PROJECTILE = preload("Player_Projectile.tscn")
const STRONGER_PROJECTILE = preload("Stronger_Player_Projectile.tscn")

var ACTIVE_PROJECTILE

onready var PlayerModel = $PlayerModel
onready var PlayerHitbox = $PlayerHitbox
onready var GUI = $"../GUI"

var playerMotion = Vector2()
var timeSinceLastShot = 10 #Able to shoot right away
var alive = true

var nearbyItem #When an item is on the ground near the player. Usually null
var equippedItem #The one special item that is equipped. Usually null
var activeBuffs = {}

func _ready():
	ACTIVE_PROJECTILE = NORMAL_PROJECTILE
	GUI.updateMaxHealth(MAX_HEALTH)
	GUI.updateCurrentHealth(HEALTH)

func _process(delta):
	if nearbyItem != null and Input.is_action_just_pressed("ui_pickup_item"):
		if nearbyItem.type == 'Equipment':
			if equippedItem != null:
				dropItem(equippedItem)
		nearbyItem.pickup(self)

func onHealthChange(change): #Negative value for damage
	GUI.updateCurrentHealth(max(HEALTH,0))

func turn(angle):
		PlayerModel.rotation = angle
		PlayerHitbox.rotation = angle

func onPlayerDeath():
	self.queue_free()
	alive = false
	#Play death animation / "You lose" screen
	print("YOU DIED!")

func takeDamage(damage): 
	#Add special functionality here later
	HEALTH -= damage
	onHealthChange(-damage)
	if HEALTH <= 0:
		onPlayerDeath()

func gainHealth(healthGain):
	#Add special functionality here
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
	if not alive:
		return
	timeSinceLastShot += delta
	if Input.is_action_just_pressed("ui_shoot") and timeSinceLastShot > RELOAD_TIME:
		shoot(get_viewport().get_mouse_position())
	calculate_player_movement()
	move_and_slide(playerMotion)
	
func onProjectileHit(damage):
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