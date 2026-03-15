extends Control

@onready var back_button = $MarginContainer/HBoxContainer/BackToMenuButton

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Här kollar vi vilken fil AiManager sa åt oss att ladda!
	if AiManager.file_to_edit != "":
		print("Välkommen till editorn! Vi ska redigera: ", AiManager.file_to_edit)
	else:
		print("Ingen fil angiven, något blev fel i övergången.")

func _on_back_button_pressed():
	# Byt ut sökvägen till din meny om den heter något annat
	get_tree().change_scene_to_file("res://menus/CreateAndEditAI.tscn")
