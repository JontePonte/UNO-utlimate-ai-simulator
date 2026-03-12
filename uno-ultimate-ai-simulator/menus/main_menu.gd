extends Control

@onready var play_single_game_button = $MarginContainer/MainVBox/PlaySingleGameButton
@onready var multiple_ai_games_button = $MarginContainer/MainVBox/MultipleAIGamesButton
@onready var create_new_ai_button = $MarginContainer/MainVBox/CreateNewAIButton
@onready var exit_game_button = $MarginContainer/MainVBox/ExitGameButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_single_game_button.pressed.connect(_on_single_game_burron_pressed)
	multiple_ai_games_button.pressed.connect(_on_multiple_ai_games_button_pressed)
	create_new_ai_button.pressed.connect(_on_create_new_ai_button_pressed)
	exit_game_button.pressed.connect(_exit_game_button_pressed)

func _on_single_game_burron_pressed():
	get_tree().change_scene_to_file("res://menus/MatchSetup.tscn")

func _on_multiple_ai_games_button_pressed():
	pass

func _on_create_new_ai_button_pressed():
	pass

func _exit_game_button_pressed():
	get_tree().quit()
