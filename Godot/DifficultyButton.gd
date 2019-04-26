extends Button

func _on_pressed():
	get_node("/root/MainMenu").changeDifficulty($Label.text)
