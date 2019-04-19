extends MarginContainer

onready var LABEL = $HBoxContainer/Bars/HPBar/Count/Background/Number
onready var PROGRESS_BAR = $HBoxContainer/Bars/HPBar/Gauge

func updateCurrentHealth(currentHP):
	LABEL.text = str(currentHP)
	PROGRESS_BAR.value = currentHP

func updateMaxHealth(maxHP):
	PROGRESS_BAR.max_value = maxHP
