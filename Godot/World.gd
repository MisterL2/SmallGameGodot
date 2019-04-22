extends Node2D

onready var ENEMIES = $Enemies.get_children()

onready var PLAYER = $Player

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	print("Welcome to my small Godot Game v0.4")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			
func _physics_process(delta):
	if not is_instance_valid(PLAYER):
		if Input.is_action_just_pressed("ui_select"): #Restart game when spacebar is pressed
			get_tree().reload_current_scene() #Restarting game
		return
	var playerPos = get_player_pos()
	var toBeRemoved = []
	if not ENEMIES:
		print("All enemies dead!")
	for enemy in ENEMIES:
		if is_instance_valid(enemy): #Excludes enemies that were previously freed
			enemy.maybeShoot(delta, playerPos)
		else:
			toBeRemoved.append(enemy)
	for freedEnemy in toBeRemoved:
		ENEMIES.remove(ENEMIES.find(freedEnemy))

func get_player_pos():
		return PLAYER.position