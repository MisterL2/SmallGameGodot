extends Area2D

const type = "Regular"

func _on_Entity_nearby(body):
	print("someone is near an item!")
	if body.has_method("onKeyPickup"): #Automatic pickup
		body.onKeyPickup(type)
		self.queue_free()