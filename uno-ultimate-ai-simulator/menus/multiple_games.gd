extends Control

@onready var start_button = $MarginContainer/MainVBox/ButtonHBox/Start
@onready var exit_button = $MarginContainer/MainVBox/ButtonHBox/ExitGame
@onready var main_menu_button = $MarginContainer/MainVBox/ButtonHBox/Back


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Koppla knappar
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)


func _on_start_button_pressed():
	
	var err = get_tree().change_scene_to_file("res://game/VisualMatch.scn")
	if err != OK:
		print("Kunde inte ladda VisualMatch! Felkod: ", err)

func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
