extends Area2D

#const type = [Equipment / Buff / Effect]

func _on_Entity_nearby(body):
	print("someone is near an item!")
	if body.has_method("onFindItem"):
		body.onFindItem(self) #The player may or may not pick up the item. A call will be made to "pickup" if the player decides to pick up the item

func _on_Entity_left(body):
	print("someone left an item!")
	if body.has_method("onLeaveItem"):
		body.onLeaveItem(self)

func pickup(player):
	item_effect(player) #Do special item effect to player or add item to inventory
	self.queue_free() #Deletes the entity after it goes into the player inventory

func item_effect(player): #This function will be overwritten by any actual item extending this!
	print("This should NEVER be called! (Item class!)")
	pass 


