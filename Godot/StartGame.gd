extends Button

func _ready():
	call_deferred("make_visible")

func make_visible(): #Set visible only in the starting screen!
	if $"/root/Base".gameState == 'Initial':
		self.visible = true

func _on_pressed():
	$"/root/Base".start_game()
