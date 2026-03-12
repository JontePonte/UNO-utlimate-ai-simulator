extends Control

# Uppdatera sökvägen så den pekar på din faktiska Start-knapp i scen-trädet
@onready var start_button = $MarginContainer/MainVBox/ButtonHBox/Start

func _ready():
	# Koppla knappen till funktionen
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	print("Startar match med nuvarande GameSettings...")
	
	# Byt scen till VisualMatch! 
	# (Från dina bilder ser jag att filen heter VisualMatch.scn och ligger i game-mappen)
	var err = get_tree().change_scene_to_file("res://game/VisualMatch.scn")
	
	if err != OK:
		print("Kunde inte ladda VisualMatch! Felkod: ", err)
