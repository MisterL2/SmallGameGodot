extends Area2D

onready var next_scene_path 

func _on_LevelGoal_reached(body): #Based on collision mask, this should ONLY collide with the player!
	print("Level goal reached!")
	$"/root/Base".goto_scene(next_scene_path)
