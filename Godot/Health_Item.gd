extends "res://Item.gd"

const type = "Effect"

func item_effect(player): #Overwriting the item_effect function from item in order to implement it
	print("Healing player!")
	player.gainHealth(300)