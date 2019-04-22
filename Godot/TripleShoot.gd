extends "res://Item.gd"

const type = "Buff"

func item_effect(player):
	player.activeBuffs["TripleShoot"] = 15 #TripleShoot Buff is available for 15 attacks, refreshes whenever a new instance of it is picked up.