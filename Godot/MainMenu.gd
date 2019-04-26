extends Control

func changeDifficulty(newDifficulty):
	$"/root/Base".change_difficulty(newDifficulty)
	$UpperRow/NinePatchRect/DifficultySelection/HBoxContainer/DifficultyLabel.text = newDifficulty
