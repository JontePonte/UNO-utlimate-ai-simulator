extends Control

@export var ai_list_item_scene: PackedScene 

@onready var ai_list_container = $MarginContainer/MainVBox/MainHBox/VBoxRightSide/ScrollContainer/AIListContainer
@onready var main_menu_button = $MarginContainer/MainVBox/MainHBox/VBoxLeftSide/BottomHBox/HBoxBackExit/Back
@onready var exit_game_button = $MarginContainer/MainVBox/MainHBox/VBoxLeftSide/BottomHBox/HBoxBackExit/ExitGame

# -- POPUPS --
@onready var name_dialog = $NameDialog
@onready var name_input = $NameDialog/LineEdit
@onready var delete_dialog = $DeleteDialog

# -- VARIABLER FÖR ATT MINNAS VAD VI KLICKADE PÅ --
var current_file_to_copy: String = ""
var current_file_to_delete: String = "" # NY! Minns vilken fil som ska raderas

func _ready():
	populate_ai_list()
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	exit_game_button.pressed.connect(_on_exit_button_pressed)
	
	# Koppla OK-knapparna för våra popups
	name_dialog.confirmed.connect(_on_name_dialog_confirmed)
	delete_dialog.confirmed.connect(_on_delete_dialog_confirmed) # NY!

func populate_ai_list():
	for child in ai_list_container.get_children():
		child.queue_free()
		
	var ai_files = AiManager.get_all_ai_files()
	for file_name in ai_files:
		_create_list_item(file_name)

func _create_list_item(file_name: String):
	var item = ai_list_item_scene.instantiate()
	ai_list_container.add_child(item)
	
	var display_name = file_name.replace(".json", "") 
	item.setup_item(display_name, file_name)
	
	# Lyssna på signaler från raden
	item.copy_requested.connect(_on_ai_copy_requested)
	item.delete_requested.connect(_on_ai_delete_requested) # NY! Lyssna på delete

# --- DELETE LOGIK ---

func _on_ai_delete_requested(file_name: String):
	current_file_to_delete = file_name
	
	# Gör varningstexten dynamisk så man ser exakt VAD man raderar
	var display_name = file_name.replace(".json", "")
	delete_dialog.dialog_text = "Are you sure you want to delete '" + display_name + "'?\nThis cannot be undone."
	
	# Visa rutan!
	delete_dialog.popup_centered()

func _on_delete_dialog_confirmed():
	if current_file_to_delete == "":
		return
		
	# Bygg stigen till filen
	var path_to_delete = AiManager.AI_FOLDER_PATH + current_file_to_delete
	
	# Berätta för Godot att radera filen direkt från datorn
	var err = DirAccess.remove_absolute(path_to_delete)
	
	if err == OK:
		print("Raderade: " + current_file_to_delete)
		populate_ai_list() # Ladda om listan så filen försvinner visuellt
	else:
		print("Kunde inte radera filen! Felkod: ", err)
		
	# Nollställ minnet
	current_file_to_delete = ""

# --- KOPIERINGS LOGIK (Oförändrad) ---

func _on_ai_copy_requested(original_file_name: String):
	current_file_to_copy = original_file_name
	var default_name = original_file_name.replace(".json", "") + " Copy"
	name_input.text = default_name
	name_dialog.popup_centered()
	name_input.grab_focus()

func _on_name_dialog_confirmed():
	var new_name = name_input.text.strip_edges()
	if new_name == "": return
	if not new_name.ends_with(".json"): new_name += ".json"
		
	var base_dir = AiManager.AI_FOLDER_PATH
	var source_path = base_dir + current_file_to_copy
	var dest_path = base_dir + new_name
	
	var file_to_copy = FileAccess.open(source_path, FileAccess.READ)
	if file_to_copy:
		var content = file_to_copy.get_as_text()
		file_to_copy.close()
		
		var new_file = FileAccess.open(dest_path, FileAccess.WRITE)
		new_file.store_string(content)
		new_file.close()
		
		print("Kopierade till: " + new_name)
		populate_ai_list()

# --- NAVIGATION ---

func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
