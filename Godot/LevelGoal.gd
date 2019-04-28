extends Area2D

func _on_LevelGoal_reached(body): #Based on collision mask, this should ONLY collide with the player!
	print("Level goal reached!")
	$"/root/Base".goto_scene("res://WarehouseBoss.tscn")
