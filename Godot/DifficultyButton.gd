extends Button

func _ready():
	call_deferred("self_press")
	
func self_press():
	if self.name == $"/root/Base".DIFFICULTY:
		self.grab_focus()
		self.disabled = true

func _on_pressed():
	$"/root/MainMenu".changeDifficulty($Label.text)
	for button in self.get_parent().get_children():
		button.disabled = false
	self.disabled = true
