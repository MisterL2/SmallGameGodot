extends KinematicBody2D

const type = "LevelLock"

var models = [preload("res://LevelLock//LevelLock_base.png"),preload("res://LevelLock//LevelLock_1.png"),preload("res://LevelLock//LevelLock_2.png"),preload("res://LevelLock//LevelLock_3.png"),preload("res://LevelLock//LevelLock_4.png")]

var keys = 0
var moving = false
var ticks = 0

func interact(player): #Default function called on all interactable objects
	if keys == models.size()-1:
		print("Accepting no more keys!")
	elif player.keys >= 1: #Enter one key with each interaction
		player.keys -=1
		keys+=1
		$Sprite.texture = models[keys]
		if keys == 4:
			moving = true
			#Become uncollidable and disappear to any side, so that it goes "into" a wall. (Behind the wall with z-index)
			self.set_collision_layer(0)
			self.set_collision_mask(0)
	else:
		print("Player has no keys!")

func _physics_process(delta):
	if moving:
		ticks += 1
		move_and_slide(Vector2(0,-1)*50)
	if ticks == 100: # "Animation" completed
		self.queue_free()