extends Button

func _on_pressed():
	$"../../../Master".DIFFICULTY = self.text
