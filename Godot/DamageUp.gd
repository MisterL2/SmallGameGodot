extends "res://Item.gd"

const type = "Buff"

func item_effect(player):
	player.activeBuffs["DamageUp"] = 30 #Buff persists for 30 attacks