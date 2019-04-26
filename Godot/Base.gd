extends Node

var current_scene = null #Always the game scene or null, never the menu
var current_scene_path = null
var ENEMIES = [] 
var PLAYER = null

var DIFFICULTY = 'Hard'
var gameState = 'Initial' #Pause always opens up menu

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Welcome to my small Godot Game v0.5")
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	call_deferred("open_menu")

func start_game():
	close_menu()
	print("Starting new game with difficulty " + DIFFICULTY)
	goto_scene("res://Warehouse.tscn")

func pause_game():
	print("Game paused!")
	get_tree().paused = true #Freezes all nodes by default. Excluded from this are THIS node, and the MainMenu
	gameState = 'Paused'
	open_menu()

func unpause_game():
	print("Game resumed!")
	close_menu()
	gameState = 'Active'
	get_tree().paused = false

func open_menu():
	open_scene("res://MainMenu.tscn") #No return value, so the current_scene is still the background scene!

func close_menu():
	$"/root/MainMenu".queue_free()
	get_tree().set_current_scene(current_scene) #current_scene is the main scene, never the menu

func open_scene(path):	
	var s = ResourceLoader.load(path)
    # Instance the new scene.
	var new_scene = s.instance()
    # Add it to the active scene, as child of root.
	get_tree().get_root().add_child(new_scene)
	
    # Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(new_scene)
	return new_scene

func goto_scene(path):
    # This function will usually be called from a signal callback,
    # or some other function in the current scene.
    # Deleting the current scene at this point is
    # a bad idea, because it may still be executing code.
    # This will result in a crash or unexpected behavior.

    # The solution is to defer the load to a later time, when
    # we can be sure that no code from the current scene is running:
    call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path): #For actual scene changes, not menu
    # It is now safe to remove the current scene
	if current_scene != null:
		current_scene.free()

    # Instance the new scene.
	current_scene = open_scene(path)
	current_scene_path = path #Only called for actual scene changes, not menu! Produces hard-to-find bugs when restarting otherwise!
	
	if gameState == 'Initial' or gameState == 'Active' or gameState == 'Restart':
		load_enemies()
	if (PLAYER == null and gameState == 'Initial') or gameState == 'Restart': #UNLIKE ENEMIES, Player is only received from the FIRST scene, and then copied into future scenes!
		load_player()
		
	#Update gameState (Must be HERE for this gameState due to deferred call!)
	if gameState == 'Initial':
		gameState = 'Active'
	elif gameState == 'Restart':
		gameState = 'Active'

func load_player():
	print("Loading player...")
	PLAYER = current_scene.get_node("Player")

func load_enemies():
	print("Loading enemies...")
	ENEMIES = current_scene.get_node("Enemies").get_children()

func change_difficulty(newDifficulty):
	print("Difficulty changed from " + DIFFICULTY + " to " + newDifficulty)
	if gameState == 'Active' and PLAYER != null and is_instance_valid(PLAYER):
		PLAYER.on_difficulty_change(self.DIFFICULTY,newDifficulty)
	self.DIFFICULTY = newDifficulty

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CONFINED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	if Input.is_action_just_pressed("ui_select"): #Restart game when spacebar is pressed
		if gameState == 'GameOver':
			print(PLAYER)
			#get_tree().reload_current_scene() #Restarting game
			gameState = 'Restart'
			goto_scene(current_scene_path)
			print(PLAYER)
			
			get_tree().paused = false
			
			print(PLAYER)
			print("........")
			
		elif gameState == 'Active':
			pause_game()
		elif gameState == 'Paused':
			unpause_game()

func _physics_process(delta):
	if gameState == 'Active':
		if not is_instance_valid(PLAYER): #Should only occur on game restart
			print("Invalid")
			print(PLAYER)
			#load_player()
			#load_enemies()
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

func onPlayerDeath():
	gameState = 'GameOver'
	get_tree().paused = true

func get_player_pos():
	return PLAYER.position