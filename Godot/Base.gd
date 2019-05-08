extends Node

var current_scene = null #Always the game scene or null, never the menu
var current_scene_path = null
var ENEMIES = [] 
var PLAYER = null
var serializedPlayer = [0,0,0,{},0] #HP, MaxHP, Damage, activeBuffs, keys

enum Layer {ENVIRONMENT = 1, PLAYER = 2, ENEMY = 4, ITEM = 512, FRIENDLY_ENVIMMUNE_PROJECTILE = 1024, FRIENDLY_PROJECTILE = 2048, ENEMY_PROJECTILE = 4096, ENEMY_ENVIMMUNE_PROJECTILE = 8192, INTERACTABLE = 524288}

var DIFFICULTY = 'Medium'
var gameState = 'Initial' #Pause always opens up menu

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Welcome to my small Godot Game v0.6.2")
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	call_deferred("open_menu")

func start_game():
	close_menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
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
	if is_instance_valid(PLAYER):
		serializedPlayer = [PLAYER.HEALTH, PLAYER.MAX_HEALTH, PLAYER.DAMAGE, PLAYER.activeBuffs, PLAYER.keys]
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path): #For actual scene changes, not menu
    # It is now safe to remove the current scene
	if current_scene != null:
		current_scene.free()

    # Instance the new scene.
	current_scene = open_scene(path)
	current_scene_path = path #Only called for actual scene changes, not menu! Produces hard-to-find bugs when restarting otherwise!
	
	if 'YouWin.tscn' in path:
		print("Congratulations, you win!")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) #Frees mouse again at the end
		return
		
	if gameState in ['Initial','Active','Restart'] :
		load_enemies()
	if gameState in ['Initial','Active','Restart'] and (not is_instance_valid(PLAYER) or PLAYER.is_queued_for_deletion()): #Player deleted on newlevel.
		PLAYER = load("res://Player.tscn").instance() #Creates new player instance
		PLAYER.set_position(Vector2(80,464))
		current_scene.add_child(PLAYER) #Important! Otherwise PLAYER does not appear.
		if gameState == 'Active':
			unpack_player() #Stats from previous scene are remembered
	else:
		print("CRITICAL: Player respawn fail!")
	print(PLAYER)
	PLAYER.on_difficulty_change(DIFFICULTY) #Doesn't change anything, but updates the GUI

		
	#Update gameState (Must be HERE for this gameState due to deferred call!)
	if gameState == 'Initial':
		gameState = 'Active'
	elif gameState == 'Restart':
		gameState = 'Active'

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
			gameState = 'Restart'
			goto_scene(current_scene_path)
			get_tree().paused = false
			
		elif gameState == 'Active':
			pause_game()
		elif gameState == 'Paused':
			unpause_game()
	
	if Input.is_action_just_pressed("reset"):
		get_tree().paused = false
		goto_scene(current_scene_path)

func _physics_process(delta):
	if Input.is_action_just_pressed("next_level_cheat"):
		current_scene.get_node("LevelGoal")._on_LevelGoal_reached(null) #Moves to next level
	if gameState == 'Active':
		if not is_instance_valid(PLAYER): #Should only occur on game restart
			print("Invalid")
			print(PLAYER)
			return
		var playerPos = get_player_pos()
		
		if not ENEMIES:
			print("All enemies dead!")
		
		var toBeRemoved = []
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
	
func unpack_player():
	PLAYER.set_health(serializedPlayer[0],serializedPlayer[1])
	PLAYER.DAMAGE = serializedPlayer[2]
	PLAYER.activeBuffs = serializedPlayer[3]
	PLAYER.keys = serializedPlayer[4] #Should always be zero on level-change rn
	if PLAYER.keys > 0:
		print("Player has keys after level change. Intended or not?")