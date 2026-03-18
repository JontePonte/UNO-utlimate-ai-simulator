extends Control

@export var ai_list_item_scene: PackedScene 

@onready var ai_list_container = $MarginContainer/MainVBox/MainHBox/VBoxRightSide/ScrollContainer/AIListContainer
@onready var main_menu_button = $MarginContainer/MainVBox/MainHBox/VBoxLeftSide/BottomHBox/HBoxBackExit/Back
@onready var exit_game_button = $MarginContainer/MainVBox/MainHBox/VBoxLeftSide/BottomHBox/HBoxBackExit/ExitGame

@onready var create_new_btn = $MarginContainer/MainVBox/MainHBox/VBoxLeftSide/CreateNewAIButton

# -- POPUPS --
@onready var name_dialog = $NameDialog
@onready var name_input = $NameDialog/LineEdit
@onready var delete_dialog = $DeleteDialog

# -- VARIABLER FÖR ATT MINNAS VAD VI KLICKADE PÅ --
var current_file_to_copy: String = ""
var current_file_to_delete: String = "" # NY! Minns vilken fil som ska raderas
var dialog_mode: String = ""

func _ready():
	populate_ai_list()
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	exit_game_button.pressed.connect(_on_exit_button_pressed)
	create_new_btn.pressed.connect(_on_create_new_pressed)
	
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
	
	# --- NYTT: Kolla om filen finns i res:// (Då är det en standard-AI) ---
	var is_standard = FileAccess.file_exists("res://ai_profiles/" + file_name)
	
	# Skicka in vår nya is_standard-variabel
	item.setup_item(display_name, file_name, is_standard)
	
	# Lyssna på signalerna (De skickas ju bara om knapparna faktiskt finns och kan klickas på!)
	item.delete_requested.connect(_on_ai_delete_requested)
	item.edit_requested.connect(_on_ai_edit_requested)
	item.copy_requested.connect(_on_ai_copy_requested)
	item.export_requested.connect(_on_ai_export_requested)

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
	dialog_mode = "copy" # <-- Berätta att vi kopierar!
	var default_name = original_file_name.replace(".json", "") + " Copy"
	name_input.text = default_name
	name_dialog.popup_centered()
	name_input.grab_focus()

# --- ÖPPNA EDITORN (EDIT) ---
func _on_ai_edit_requested(file_name: String):
	# Berätta för manager vilken fil som gäller
	AiManager.file_to_edit = file_name
	
	# Byt scen! (Uppdatera sökvägen till din nya ai_editor-mapp)
	get_tree().change_scene_to_file("res://ai_editor/AIEditor.tscn")

# --- SKAPA NY AI ---
func _on_create_new_pressed():
	dialog_mode = "create" # Vi återanvänder samma popup som förut!
	name_dialog.title = "Create New AI"
	name_input.text = "My_New_AI"
	name_dialog.popup_centered()
	name_input.grab_focus()

func _on_name_dialog_confirmed():
	var new_name = name_input.text.strip_edges()
	if new_name == "": return
	if not new_name.ends_with(".json"): new_name += ".json"
		
	if dialog_mode == "copy":
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

	elif dialog_mode == "create":
		var dest_path = AiManager.AI_FOLDER_PATH + new_name
		
		# Vi skapar en tom JSON-struktur för att grunda filen
		var empty_data = {
			"nodes": [],
			"connections": []
		}
		
		var new_file = FileAccess.open(dest_path, FileAccess.WRITE)
		new_file.store_string(JSON.stringify(empty_data, "\t"))
		new_file.close()
		
		print("Skapade ny AI: ", new_name)
		
		# Skicka användaren direkt in i Editorn!
		AiManager.file_to_edit = new_name
		get_tree().change_scene_to_file("res://ai_editor/AIEditor.tscn")

# --- NAVIGATION ---
func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")

func _on_ai_export_requested(file_name: String):
	# Bygg stigen till filen
	var file_path = AiManager.AI_FOLDER_PATH + file_name
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		# Klistra in texten i datorns urklipp (Clipboard)
		DisplayServer.clipboard_set(json_string)
		
		# Visa vår snygga notis
		_show_toast("AI Code exported! Right-click and 'Paste' to share it.")
	else:
		_show_toast("Error: Could not find AI file!")

# --- TOAST NOTIFICATION ---
func _show_toast(message: String):
	var toast = Label.new()
	toast.text = message
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	toast.add_theme_stylebox_override("normal", style)
	
	add_child(toast)
	
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast.position.y -= 120 
	
	var tween = create_tween()
	tween.tween_interval(3.0) 
	tween.tween_property(toast, "modulate:a", 0.0, 1.0) 
	tween.tween_callback(toast.queue_free)
