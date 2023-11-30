extends CanvasLayer

var is_muted = false

func _ready():
	$StartButton.connect("pressed", self, "_on_StartButton_pressed")
	$L2.connect("pressed", self, "_on_L2_pressed")
	$L3.connect("pressed", self, "_on_L3_pressed")
	$MuteButton.connect("pressed", self, "_on_MuteButton_pressed")
	$QuitButton.connect("pressed", self, "_on_QuitButton_pressed")

func _on_StartButton_pressed():
	get_tree().change_scene("res://scenes/level1.tscn")

func _on_L2_pressed():
	get_tree().change_scene("res://scenes/level2.tscn")

func _on_L3_pressed():
	get_tree().change_scene("res://scenes/level3.tscn")

func _on_MuteButton_pressed():
	is_muted = !is_muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted)
	pass

func _on_QuitButton_pressed():
	get_tree().quit()
