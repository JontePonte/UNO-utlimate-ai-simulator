extends Control

# Dra in din 'ai_list_item.tscn' här via Inspektorn i Godot!
@export var ai_list_item_scene: PackedScene 

# Uppdatera sökvägen här så den matchar ditt träd exakt
@onready var ai_list_container = $MarginContainer/MainVBox/MainHBox/VBoxRightSide/ScrollContainer/AIListContainer
@onready var main_menu_button = $MarginContainer/MainVBox/MainHBox/VBoxLeftSide/BottomHBox/HBoxBackExit/Back
@onready var exit_game_button = $MarginContainer/MainVBox/MainHBox/VBoxLeftSide/BottomHBox/HBoxBackExit/ExitGame

# Mappen där vi sparar alla AI-filer
const AI_FOLDER_PATH = "res://ai_profiles/"

func _ready():
	_ensure_ai_folder_exists()
	populate_ai_list()
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	exit_game_button.pressed.connect(_on_exit_button_pressed)

# Se till att mappen faktiskt finns första gången spelet startas
func _ensure_ai_folder_exists():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("ai_profiles"):
		dir.make_dir("ai_profiles")
		# Här kan vi senare lägga in kod som kopierar dina "Standard AI:s" från res:// till user://

# Den här funktionen bygger själva listan
func populate_ai_list():
	for child in ai_list_container.get_children():
		child.queue_free()
		
	# Hämta listan från vår nya Autoload!
	var ai_files = AiManager.get_all_ai_files()
	
	for file_name in ai_files:
		_create_list_item(file_name)

# Skapar en instans av raden och lägger till den i UI:t
func _create_list_item(file_name: String):
	var item = ai_list_item_scene.instantiate()
	ai_list_container.add_child(item)
	
	# Ta bort ".json" från namnet så det ser snyggt ut i listan
	var display_name = file_name.replace(".json", "") 
	item.setup_item(display_name)
	
func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
