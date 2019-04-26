extends Label

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	self.text = $"/root/Base".DIFFICULTY #Defaults to "Hard" at the start and remembers the previous selection afterwards