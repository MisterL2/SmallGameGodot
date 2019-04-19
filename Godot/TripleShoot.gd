extends "res://Item.gd"

const type = "Buff"

func item_effect(player):
	player.activeBuffs["TripleShoot"] = 10 #TripleShoot Buff is available for 20 ticks, refreshes whenever a new instance of it is picked up.