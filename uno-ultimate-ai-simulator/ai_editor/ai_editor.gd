extends Control

@export var root_node_scene: PackedScene

@export var action_draw_node_scene: PackedScene
@export var action_play_node_scene: PackedScene

@export var condition_hand_node_scene: PackedScene
@export var condition_table_color_node_scene: PackedScene
@export var condition_opponent_card_count: PackedScene
@export var condition_player_count: PackedScene
@export var condition_playable_card_count: PackedScene

@onready var back_button = $MarginContainer/HBoxContainer/BackToMenuButton
@onready var fullscreen_button = $MarginContainer/HBoxContainer/FullscreenButton
@onready var rename_button = $MarginContainer/HBoxContainer/RenameButton
@onready var copy_button = $MarginContainer/HBoxContainer/CopyButton
@onready var save_button = $MarginContainer/HBoxContainer/SaveButton
@onready var test_menu_button = $MarginContainer/HBoxContainer/TestButton

@onready var graph_edit = $GraphEdit
@onready var context_menu = $GraphContextMenu
@onready var node_context_menu = $NodeContextMenu

var right_click_position: Vector2 = Vector2.ZERO
var node_to_edit: GraphNode = null

var is_right_dragging: bool = false
var has_panned: bool = false
var right_click_start_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD: float = 10.0 # Antal pixlar vi tillåter musen att skaka

var rename_dialog: ConfirmationDialog
var rename_input: LineEdit

var has_unsaved_changes: bool = false
var unsaved_dialog: ConfirmationDialog

func _ready():
	AiManager.ai_node_executing.connect(_on_ai_node_executing)
	back_button.pressed.connect(_on_back_button_pressed)
	fullscreen_button.pressed.connect(_on_fullscreen_button_pressed)
	copy_button.pressed.connect(_on_copy_button_pressed)
	rename_button.pressed.connect(_on_rename_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	
	# Hämta popup-menyn som tillhör knappen
	var popup = test_menu_button.get_popup()
	popup.clear()
	popup.add_item("Test: 2 Players") # Blir ID 0
	popup.add_item("Test: 3 Players") # Blir ID 1
	popup.add_item("Test: 4 Players") # Blir ID 2
	
	# Koppla signalen när man klickar på ett alternativ i listan
	popup.id_pressed.connect(_on_test_match_selected)
	
	context_menu.add_item("Action: Draw Card", 0)
	context_menu.add_item("Action: Play Card", 1)
	context_menu.add_item("Condition: Check Hand", 2)
	context_menu.add_item("Condition: Compare Opponent Hand", 3)
	context_menu.add_item("Condition: Playable Card Count Is", 4)
	context_menu.add_item("Condition: Table Color Is", 5)
	context_menu.add_item("Condition: Player Count Is", 6)
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	context_menu.window_input.connect(_on_menu_window_input.bind(context_menu))
	node_context_menu.window_input.connect(_on_menu_window_input.bind(node_context_menu))
	
	# Lyssna på när GraphEdit ber om en högerklicksmeny (popup_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)	
	graph_edit.gui_input.connect(_on_graph_edit_gui_input)
	
	# Sätt upp vår nya nod-meny
	node_context_menu.add_item("Copy Node", 0)
	node_context_menu.add_item("Remove Node", 1)
	node_context_menu.id_pressed.connect(_on_node_context_menu_id_pressed)
	
	if AiManager.file_to_edit != "":
		print("Laddar AI: ", AiManager.file_to_edit)
		_load_ai_graph(AiManager.file_to_edit)
	else:
		print("Ingen fil angiven, något blev fel i övergången.")
	
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	
	_setup_rename_dialog()
	_setup_unsaved_dialog()
	
	# Lyssna på F11-tryck från Autoloaden (Byt ut GlobalInputs om din autoload heter något annat!)
	GlobalInputs.window_mode_changed.connect(_update_fullscreen_button_text)
	
	# Kolla vilket läge vi är i just nu och sätt rätt starttext
	var main_id = DisplayServer.MAIN_WINDOW_ID
	var is_full = DisplayServer.window_get_mode(main_id) != DisplayServer.WINDOW_MODE_WINDOWED
	_update_fullscreen_button_text(is_full)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	# Godkänn sladden och be GraphEdit att rita den permanent!
	_mark_unsaved()
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	# Ta bort sladden om användaren kopplar loss den
	_mark_unsaved()
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _on_back_button_pressed():
	if has_unsaved_changes:
		unsaved_dialog.popup_centered()
	else:
		get_tree().change_scene_to_file("res://menus/CreateAndEditAI.tscn")

# Körs när man klickar på knappen med musen
func _on_fullscreen_button_pressed():
	GlobalInputs.toggle_window_mode()

# Uppdaterar texten (Körs både vid musklick och F11-tryck)
func _update_fullscreen_button_text(is_fullscreen: bool):
	if is_fullscreen:
		fullscreen_button.text = "Windowed (F11)"
	else:
		fullscreen_button.text = "Fullscreen (F11)"

func _on_context_menu_id_pressed(id: int):
	_mark_unsaved()
	
	var new_node: GraphNode = null
	
	# 1. Bestäm vilken scen som ska instansieras
	if id == 0:
		new_node = action_draw_node_scene.instantiate()
	elif id == 1:
		new_node = action_play_node_scene.instantiate()
	elif id == 2:
		new_node = condition_hand_node_scene.instantiate()
	elif id == 3:
		new_node = condition_opponent_card_count.instantiate()
	elif id == 4:
		new_node = condition_playable_card_count.instantiate()
	elif id == 5:
		new_node = condition_table_color_node_scene.instantiate()
	elif id == 6:
		new_node = condition_player_count.instantiate()
		
	# 2. Om vi faktiskt skapade en nod, ställ in den!
	if new_node != null:
		graph_edit.add_child(new_node)
		new_node.dragged.connect(_mark_unsaved.unbind(2))
		
		#Räkna ut exakt var på duken vi befinner oss, med hänsyn till scroll och zoom!
		var mouse_pos = graph_edit.get_local_mouse_position()
		new_node.position_offset = (mouse_pos + graph_edit.scroll_offset) / graph_edit.zoom
		
		# Säg åt den nya noden att lyssna på musklick
		new_node.gui_input.connect(_on_node_gui_input.bind(new_node))
		
		# --- BONUS: Få Stjärnan (*) att dyka upp när man ändrar en rullgardin! ---
		var dropdown = new_node.get_node_or_null("OptionDropdown")
		if not dropdown: dropdown = new_node.get_node_or_null("OptionsDropdown")
		if not dropdown: dropdown = new_node.get_node_or_null("OptionButton")
		
		if dropdown:
			dropdown.item_selected.connect(func(_idx): _mark_unsaved())
		
		var opponent_dropdown = new_node.get_node_or_null("OpponentDropdown")
		if opponent_dropdown:
			opponent_dropdown.item_selected.connect(func(_idx): _mark_unsaved())
			
		var color_dropdown = new_node.get_node_or_null("ColorDropdown")
		if color_dropdown:
			color_dropdown.item_selected.connect(func(_idx): _mark_unsaved())

func _on_node_gui_input(event: InputEvent, node: GraphNode):
	# Koll om det är ett högerklick!
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		node.accept_event()
		
		if node.name == "RootNode" or node.title == "AI Start":
			return # Hoppa ur funktionen direkt
		
		node_to_edit = node # Spara noden vi klickade på
		
		# Flytta menyn till musen och visa den
		node_context_menu.position = Vector2i(get_viewport().get_mouse_position())
		node_context_menu.popup()
		
		# Säkerhetsspärr: Hindra eleverna från att radera Start-noden!
		if node.name == "RootNode" or node.title == "AI Start":
			node_context_menu.set_item_disabled(1, true) # Gråa ut "Remove"
		else:
			node_context_menu.set_item_disabled(1, false)

func _on_node_context_menu_id_pressed(id: int):
	if node_to_edit == null: return
	_mark_unsaved()
	
	if id == 0: # COPY (Kopiera)
		# duplicate() skapar en exakt kopia av noden vi klickade på
		var duplicate_node = node_to_edit.duplicate()
		graph_edit.add_child(duplicate_node)
		
		# Flytta den lite neråt och åt höger så de inte hamnar exakt på varandra
		duplicate_node.position_offset = node_to_edit.position_offset + Vector2(30, 30)
		
		# Vi måste se till att den nya kopian OCKSÅ lyssnar på musklick!
		duplicate_node.gui_input.connect(_on_node_gui_input.bind(duplicate_node))
		
	elif id == 1: # REMOVE (Radera)
		# MYCKET VIKTIGT: Om vi bara raderar noden medan sladdar är inkopplade, kraschar spelet!
		# Vi måste först be Godot "klippa alla sladdar" som går till eller från denna nod.
		for conn in graph_edit.get_connection_list():
			if conn["from_node"] == node_to_edit.name or conn["to_node"] == node_to_edit.name:
				graph_edit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
		
		# Nu är det säkert att radera noden!
		node_to_edit.queue_free()
		node_to_edit = null

func _on_delete_nodes_request(nodes: Array[StringName]):
	# Godot ger oss en lista med namnen på alla noder som var markerade
	for node_name in nodes:
		# Hitta själva noden baserat på namnet
		var node_to_delete = graph_edit.get_node_or_null(NodePath(node_name))
		
		if node_to_delete == null:
			continue # Om noden redan är borta, hoppa till nästa
			
		# VÅRT SKYDDSNÄT: Radera ALDRIG startnoden!
		if node_to_delete.name == "RootNode" or node_to_delete.title == "AI Start":
			print("Nice try, men du får inte radera startnoden!")
			continue 
			
		# 1. Klipp alla sladdar först (precis som i högerklicksmenyn)
		for conn in graph_edit.get_connection_list():
			if conn["from_node"] == node_name or conn["to_node"] == node_name:
				graph_edit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
		
		# 2. Radera noden!
		_mark_unsaved()
		node_to_delete.queue_free()

func _on_rename_button_pressed():
	# Fyll i nuvarande namn (utan .json) i textrutan
	rename_input.text = AiManager.file_to_edit.replace(".json", "")
	# Visa rutan i mitten av skärmen
	rename_dialog.popup_centered(Vector2(300, 120))

func _on_copy_button_pressed():
	# Spara automatiskt om det behövs
	if has_unsaved_changes:
		_on_save_button_pressed()
		
	var file_path = AiManager.AI_FOLDER_PATH + AiManager.file_to_edit
	
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		# Klistra in i urklipp
		DisplayServer.clipboard_set(json_string)
		
		# Kalla på vår nya snygga popup!
		_show_toast("AI Code copied! Right-click and select 'Paste' (or press Ctrl+V) to share it.")
	else:
		_show_toast("Error: Could not find AI file!")

func _show_toast(message: String):
	# 1. Skapa en ny Label i koden
	var toast = Label.new()
	toast.text = message
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 2. Designa en snygg bakgrundsböx (Mörkgrå med rundade hörn)
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
	
	# 3. Lägg till den i scenen så den syns
	add_child(toast)
	
	# 4. Placera den i mitten, en bit upp från botten
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast.position.y -= 120 
	
	# 5. Animera bort den mjukt!
	var tween = create_tween()
	tween.tween_interval(3.0) # Vänta i 3 sekunder
	tween.tween_property(toast, "modulate:a", 0.0, 1.0) # Tona ut genomskinligheten under 1 sekund
	tween.tween_callback(toast.queue_free) # Radera noden när animationen är klar

func _on_rename_confirmed():
	var new_name = rename_input.text.strip_edges() # Ta bort onödiga mellanslag
	
	if new_name == "":
		print("Namnet får inte vara tomt!")
		return
		
	var new_filename = new_name + ".json"
	
	# Om namnet inte ens ändrades, gör ingenting
	if new_filename == AiManager.file_to_edit:
		return
		
	var new_path = AiManager.AI_FOLDER_PATH + new_filename
	
	# Kolla så vi inte råkar skriva över en annan AI
	if FileAccess.file_exists(new_path):
		print("En AI med det namnet finns redan!")
		return
		
	# Byt namn på filen via DirAccess
	var dir = DirAccess.open(AiManager.AI_FOLDER_PATH)
	if dir:
		var error = dir.rename(AiManager.file_to_edit, new_filename)
		
		if error == OK:
			print("Bytte namn från ", AiManager.file_to_edit, " till ", new_filename)
			
			# 1. Uppdatera vår globala variabel
			AiManager.file_to_edit = new_filename
			
			# 2. Det absolut smartaste tricket: Vi sparar om filen direkt!
			# Eftersom filen precis fick ett nytt namn, och vår _on_save_button_pressed
			# använder AiManager.file_to_edit för att sätta "ai_name" inuti JSON-filen,
			# så kommer ett snabbt spara-anrop här att uppdatera allt perfekt!
			_on_save_button_pressed()
		else:
			print("Kunde inte byta namn på filen. Felkod: ", error)

func _setup_rename_dialog():
	rename_dialog = ConfirmationDialog.new()
	rename_dialog.title = "Rename AI"
	rename_dialog.dialog_text = "Skriv in det nya namnet på din AI:"
	
	# Skapa en textruta där vi kan skriva
	rename_input = LineEdit.new()
	rename_dialog.add_child(rename_input)
	
	# När man trycker "OK" i rutan körs denna:
	rename_dialog.confirmed.connect(_on_rename_confirmed)
	
	# Lägg till rutan i spelet (men den är dold tills vi kallar på den)
	add_child(rename_dialog)

func _on_save_button_pressed():
	print("Sparar AI: ", AiManager.file_to_edit)
	
	# 1. Hitta vad startnoden heter (vanligtvis "RootNode")
	var start_node_name = "RootNode" 
	# Hitta vilken nod som är kopplad till startnodens enda utgång (port 0)
	var first_logic_node = _get_connected_node(start_node_name, 0)
	
	# 2. Skapa datan vi ska spara!
	var save_data = {
		"ai_name": AiManager.file_to_edit.replace(".json", ""), # Snyggt namn för UI:t
		"description": "En AI skapad i den visuella editorn.",
		"visual_data": { # HÄR lägger vi den gamla visuella datan
			"nodes": [], 
			"connections": []
		},
		# HÄR bygger vi trädet för spelet!
		"root": _build_logic_tree(first_logic_node) 
	}
	
	# 1. SPARA ALLA SLADDAR (Byt ut @ mot _)
	var all_connections = graph_edit.get_connection_list()
	for conn in all_connections:
		save_data["visual_data"]["connections"].append({
			"from_node": String(conn["from_node"]).replace("@", "_"),
			"from_port": conn["from_port"],
			"to_node": String(conn["to_node"]).replace("@", "_"),
			"to_port": conn["to_port"]
		})
	
	# 2. SPARA ALLA NODER
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node_info = {
				"name": child.name.replace("@", "_"), # Tvätta namnet!
				"title": child.title,
				"pos_x": child.position_offset.x,
				"pos_y": child.position_offset.y
			}
			
			# Spara vanliga rullgardinen (OptionDropdown)
			if child.has_node("OptionDropdown"):
				var dropdown = child.get_node("OptionDropdown")
				node_info["selected_index"] = dropdown.selected
				
			if child.has_node("ColorDropdown"):
				var color_dropdown = child.get_node("ColorDropdown")
				node_info["color_choice"] = color_dropdown.selected
				
			save_data["visual_data"]["nodes"].append(node_info)
			
			if child.has_node("OpponentDropdown"):
				var opponent_dropdown = child.get_node("OpponentDropdown")
				node_info["opponent_choice"] = opponent_dropdown.selected
				
			save_data["visual_data"]["nodes"].append(node_info)
			
	# 3. SKRIV TILL JSON-FILEN
	var file_path = AiManager.AI_FOLDER_PATH + AiManager.file_to_edit
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		# JSON.stringify formaterar vår Dictionary till snygg text. "\t" ger indrag!
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Sparandet lyckades!")
		AiManager.ai_profile_saved.emit(AiManager.file_to_edit, save_data)
	else:
		print("Kunde inte öppna filen för att spara: ", file_path)
	
	has_unsaved_changes = false
	save_button.text = "Save AI"

func _mark_unsaved():
	if not has_unsaved_changes:
		has_unsaved_changes = true
		save_button.text = "Save AI *" # Visuell feedback!

func _setup_unsaved_dialog():
	unsaved_dialog = ConfirmationDialog.new()
	unsaved_dialog.title = "Unsaved Progress"
	unsaved_dialog.dialog_text = "Du har osparade ändringar. Vill du spara innan du stänger?"
	
	# 1. Ändra standardknapparna
	unsaved_dialog.ok_button_text = "Save & Exit"
	unsaved_dialog.cancel_button_text = "Cancel"
	
	# 2. Hacka in en TREDJE knapp i Godots dialog!
	# add_button("Text", right_side, "action_name")
	unsaved_dialog.add_button("Exit without saving", true, "exit_no_save")
	
	# 3. Koppla signalerna
	unsaved_dialog.confirmed.connect(_on_save_and_exit)
	unsaved_dialog.custom_action.connect(_on_unsaved_custom_action)
	
	add_child(unsaved_dialog)

# Körs om man trycker "Save & Exit"
func _on_save_and_exit():
	_on_save_button_pressed() # Spara först!
	get_tree().change_scene_to_file("res://menus/CreateAndEditAI.tscn")

# Körs om man trycker på vår egna "Exit without saving"-knapp
func _on_unsaved_custom_action(action: StringName):
	if action == "exit_no_save":
		get_tree().change_scene_to_file("res://menus/CreateAndEditAI.tscn")

func _load_ai_graph(file_name: String):
	# 1. Rensa duken helt först
	graph_edit.clear_connections()
	for child in graph_edit.get_children():
		if child is GraphNode:
			# VIKTIGT: remove_child tvingar Godot att släppa namnet omedelbart!
			graph_edit.remove_child(child) 
			child.queue_free()

	# 2. Öppna och läs filen
	var file_path = AiManager.AI_FOLDER_PATH + file_name
	
	if not FileAccess.file_exists(file_path):
		print("Hittade ingen fil, skapar en ny blank duk med Start-nod!")
		_create_default_start_node()
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		print("Fel vid läsning av JSON-filen, spawnar Start-nod som backup!")
		_create_default_start_node()
		return
		
	var data = json.get_data()
	
	if not data.has("visual_data") or data["visual_data"]["nodes"].size() == 0:
		print("Filen saknar visuell data. Spawnar Start-nod!")
		_create_default_start_node()
		return

	print("--- BÖRJAR LADDA IN NODER ---")
	# 3. ÅTERSKAPA ALLA NODER
	for node_data in data["visual_data"]["nodes"]:
		var new_node: GraphNode = null
		
		# Säkerhets-konvertering till sträng
		var node_title = str(node_data["title"]) 
		print("Läser från JSON: Titel = '", node_title, "'")
		
		match node_title:
			"AI Start":
				new_node = root_node_scene.instantiate()
			"Condition: Check Hand":
				new_node = condition_hand_node_scene.instantiate()
			"Condition: Compare Opponet Hand":
				new_node = condition_opponent_card_count.instantiate()
			"Condition: Playable Card Count Is":
				new_node = condition_playable_card_count.instantiate()
			"Condition: Table Color Is":
				new_node = condition_table_color_node_scene.instantiate()
			"Condition: Player Count Is":
				new_node = condition_player_count.instantiate()
			"Action: Play Card":
				new_node = action_play_node_scene.instantiate()
			"Action: Draw Card":
				new_node = action_draw_node_scene.instantiate()
			_: # Detta körs om ingen av ovanstående matchar!
				print("-> FEL: Titeln '", node_title, "' matchade ingenting! Felstavat?")
				
		if new_node != null:
			# Tvätta namnet om filen har gamla '@'-tecken sparade!
			new_node.name = str(node_data["name"]).replace("@", "_")
			new_node.position_offset = Vector2(node_data["pos_x"], node_data["pos_y"])
			graph_edit.add_child(new_node)
			
			new_node.gui_input.connect(_on_node_gui_input.bind(new_node))
			new_node.dragged.connect(_mark_unsaved.unbind(2))
			
			# Ladda in vanliga rullgardinen
			if node_data.has("selected_index") and new_node.has_node("OptionDropdown"):
				var dropdown = new_node.get_node("OptionDropdown")
				dropdown.item_selected.connect(func(_idx): _mark_unsaved())
				dropdown.selected = int(node_data["selected_index"])
				
			# --- NYTT: Ladda in färg-rullgardinen och uppdatera utseendet! ---
			if node_data.has("color_choice") and new_node.has_node("ColorDropdown"):
				var color_dropdown = new_node.get_node("ColorDropdown")
				color_dropdown.item_selected.connect(func(_idx): _mark_unsaved())
				color_dropdown.selected = int(node_data["color_choice"])
				
				# Tvinga Action-noden att dölja/visa färgmenyn baserat på vad som precis laddades
				if new_node.has_method("_on_action_selected"):
					var a_dropdown = new_node.get_node_or_null("OptionDropdown")
					if a_dropdown:
						new_node._on_action_selected(a_dropdown.selected)
				
			print("-> Lade till noden: ", new_node.name)
		else:
			print("-> FEL: new_node är null! Är dina @export-scener inlagda i Inspektorn?")

	print("--- BÖRJAR DRA SLADDAR ---")
	# 4. DRA ALLA SLADDAR
	for conn in data["visual_data"]["connections"]:
		# Säkerhetstvätta sladdarna från gamla sparningar
		var safe_from = String(conn["from_node"]).replace("@", "_")
		var safe_to = String(conn["to_node"]).replace("@", "_")
		
		var err = graph_edit.connect_node(StringName(safe_from), conn["from_port"], StringName(safe_to), conn["to_port"])
		if err != OK:
			print("-> FEL: Kunde inte dra sladd från ", safe_from, " till ", safe_to)
			
	print("Laddade in AI-trädet framgångsrikt!")

func _on_test_match_selected(id: int):
	# Räkna ut antal spelare baserat på vilket alternativ (ID) vi klickade på
	var total_players = id + 2 
	
	# 1. Spara AI:n först!
	_on_save_button_pressed()
	
	# 2. Bygg sökvägen till AI:n vi redigerar just nu
	# Byt ut "res://ai_profiles/" om dina filer sparas någon annanstans
	var current_ai_path = "user://ai_profiles/" + AiManager.file_to_edit 
	var current_ai_name = "AI: " + AiManager.file_to_edit.replace(".json", "")
	
	# 3. Uppdatera GameSettings dynamiskt
	# Nollställ först alla platser så de är avstängda, men tvinga korten att synas
	for key in GameSettings.slots.keys():
		GameSettings.slots[key].active = false
		GameSettings.slots[key].is_human = false
		GameSettings.slots[key].show_cards = true # <-- Du ville att alla kort alltid ska synas!
		GameSettings.slots[key].ai_name = current_ai_name
		GameSettings.slots[key].ai_path = current_ai_path
		
	# Botten är ALLTID människa och aktiv
	GameSettings.slots["bottom"].active = true
	GameSettings.slots["bottom"].is_human = true
	GameSettings.slots["bottom"].ai_name = "You"
	
	# Aktivera rätt antal AI-motståndare baserat på valet
	if total_players == 2:
		GameSettings.slots["top"].active = true
	elif total_players == 3:
		GameSettings.slots["left"].active = true
		GameSettings.slots["right"].active = true
	elif total_players == 4:
		GameSettings.slots["left"].active = true
		GameSettings.slots["top"].active = true
		GameSettings.slots["right"].active = true
	
	# BERÄTTA ATT DETTA ÄR ETT TEST!
	GameSettings.is_test_mode = true
	
	# 4. Skapa det flytande fönstret (Samma kod som förut)
	var test_window = Window.new()
	test_window.title = "Test Match (" + str(total_players) + " players): " + AiManager.file_to_edit
	test_window.size = Vector2i(1024, 576) 
	test_window.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	
	# Sätt positionen (X, Y). 
	# X = avstånd från vänsterkant, Y = avstånd från överkant.
	test_window.position = Vector2i(850, 100)
	
	test_window.content_scale_size = Vector2i(1920, 1080)
	test_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	test_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	test_window.close_requested.connect(test_window.queue_free)
	
	var match_scene = load("res://game/VisualMatch.scn").instantiate()
	test_window.add_child(match_scene)
	add_child(test_window)

# --- VISUELL DEBUGGING ---
func _on_ai_node_executing(node_name: String):
	# Hitta noden i vår GraphEdit
	var node = graph_edit.get_node_or_null(NodePath(node_name))
	
	if node != null and node is GraphNode:
		# 1. En ännu starkare, nästan "neon-gul" färg. 
		# (Testa Color(0.5, 2.5, 0.5) om du hellre vill ha en stark grön färg!)
		node.modulate = Color(2.5, 2.5, 0.5) 
		
		# 2. Skapa en Tween
		var tween = get_tree().create_tween()
		
		# 3. NYTT TRICK: Låt noden lysa på maxstyrka i 0.5 sekunder först
		tween.tween_interval(0.5)
		
		# 4. Tona sedan mjukt tillbaka till vitt över 1.5 sekunder.
		# TRANS_SINE gör övergången mycket jämnare och lugnare än EXPO.
		tween.tween_property(node, "modulate", Color.WHITE, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _create_default_start_node():
	var root = root_node_scene.instantiate()
	root.name = "RootNode" # Tvingar den att heta RootNode internt
	root.position_offset = Vector2(40, 320) # En snygg startposition till vänster
	graph_edit.add_child(root)
	
	# Säg åt noden att lyssna på klick (så vi kan dra sladdar etc, men vår tidigare if-sats blockerar ju Remove-menyn)
	root.gui_input.connect(_on_node_gui_input.bind(root))

func _get_connected_node(from_node_name: String, from_port: int) -> String:
	for conn in graph_edit.get_connection_list():
		if conn["from_node"] == from_node_name and conn["from_port"] == from_port:
			return conn["to_node"]
	return "" # Returnerar tomt om ingen sladd är dragen

# Den magiska rekursiva funktionen (Nu med Editor-ID!)
func _build_logic_tree(current_node_name: String) -> Dictionary:
	if current_node_name == "":
		return {"type": "action", "name": "draw_card"}
		
	var node = graph_edit.get_node_or_null(NodePath(current_node_name))
	if node == null:
		return {"type": "action", "name": "draw_card"}
		
	var result = {}
	
	# --- Spara nodens namn i trädet så matchen vet vilken nod det är! ---
	result["editor_node"] = current_node_name 
	
	# ==========================================
	# 1. OM NODEN ÄR EN HANDLING (ACTION)
	# ==========================================
	if "Action:" in node.title:
		result["type"] = "action"
		
		if node.title == "Action: Draw Card":
			result["name"] = "draw_card"
			
		elif node.title == "Action: Play Card":
			# Leta efter rullgardinen säkert
			var dropdown = node.get_node_or_null("OptionDropdown")
			if not dropdown: dropdown = node.get_node_or_null("OptionsDropdown")
			if not dropdown: dropdown = node.get_node_or_null("OptionButton")
			
			if dropdown:
				match dropdown.selected:
					0: result["name"] = "play_first_playable"
					1: result["name"] = "play_first_special_card"
					2: result["name"] = "play_first_attack_card"
					3: result["name"] = "play_wild"
					4: result["name"] = "play_wild_draw_four"
					5: result["name"] = "play_draw_two"
					6: result["name"] = "play_skip"
					7: result["name"] = "play_reverse"
					8: result["name"] = "play_same_color"
					9: result["name"] = "play_same_number"
					
				# --- RÄTTAD: Hämta färgvalet för Wild-korten (som nu är Index 3 och 4!) ---
				if dropdown.selected == 3 or dropdown.selected == 4:
					var color_drop = node.get_node_or_null("ColorDropdown")
					if color_drop:
						result["color_choice"] = color_drop.selected
					else:
						result["color_choice"] = 0 # Fallback till Most numerous
			else:
				result["name"] = "play_first_playable" # Fallback om noden saknas
				
		return result
		
	# ==========================================
	# 2. OM NODEN ÄR ETT VILLKOR (CONDITION)
	# ==========================================
	elif "Condition:" in node.title:
		result["type"] = "condition"
		
		# Kolla VILKEN Condition-nod det är!
		if node.title == "Condition: Check Hand":
			var dropdown = node.get_node_or_null("OptionDropdown")
			if not dropdown: dropdown = node.get_node_or_null("OptionsDropdown")
			if not dropdown: dropdown = node.get_node_or_null("OptionButton")
			
			if dropdown != null:
				match dropdown.selected:
					0: result["name"] = "can_play_any_card"
					1: result["name"] = "has_playable_special_card"
					2: result["name"] = "has_playable_attack_card"
					3: result["name"] = "can_play_same_color"
					4: result["name"] = "can_play_same_number"
					5: result["name"] = "has_uno"
					6: result["name"] = "can_play_wild"
					7: result["name"] = "can_play_wild_draw_four"
					8: result["name"] = "can_play_draw_two"
					9: result["name"] = "can_play_skip"
					10: result["name"] = "can_play_reverse"
			else:
				result["name"] = "can_play_any_card" # Fallback
				
		elif node.title == "Condition: Table Color Is":
			var dropdown = node.get_node_or_null("OptionDropdown")
			if not dropdown: dropdown = node.get_node_or_null("OptionsDropdown")
			if not dropdown: dropdown = node.get_node_or_null("OptionButton")
			
			if dropdown != null:
				result["name"] = "compare_table_color"
				result["rank_choice"] = dropdown.selected # Spara vilket index de valde (0-3)!
			else:
				result["name"] = "compare_table_color"
				result["rank_choice"] = 0 # Fallback till most numerous
		
		# Gå vidare i trädet
		var true_node_name = _get_connected_node(current_node_name, 0)
		var false_node_name = _get_connected_node(current_node_name, 1)
		
		result["true_branch"] = _build_logic_tree(true_node_name)
		result["false_branch"] = _build_logic_tree(false_node_name)
		
		return result
		
	return {"type": "action", "name": "draw_card"}

func _input(event):
	# Kolla Ctrl+S (Spara)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S and event.is_command_or_control_pressed():
			_on_save_button_pressed()
			get_viewport().set_input_as_handled()

func _on_menu_window_input(event: InputEvent, menu: PopupMenu):
	# Fick menyn ett högerklick tagit på sig?
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		
		# Stäng just den här menyn!
		menu.hide()
		
		# Säg åt menyn att kasta klicket, så det inte blöder igenom till bakgrunden
		menu.set_input_as_handled()

func _on_graph_edit_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			is_right_dragging = true
			has_panned = false
			right_click_start_pos = event.position # Spara exakt var klicket började!
		else:
			# Knappen släpps
			if is_right_dragging:
				is_right_dragging = false
				
				# Om vi inte passerade "Deadzone"-gränsen, räknas det som ett vanligt klick!
				if not has_panned:
					right_click_position = event.position
					context_menu.position = Vector2i(get_viewport().get_mouse_position())
					context_menu.popup()
				
	elif event is InputEventMouseMotion and is_right_dragging:
		# Har vi rört musen tillräckligt långt från startpunkten?
		if not has_panned and event.position.distance_to(right_click_start_pos) > DRAG_THRESHOLD:
			has_panned = true # Nu räknas det officiellt som ett drag!
			
		# Om vi dragit tillräckligt långt, börja flytta duken
		if has_panned:
			graph_edit.scroll_offset -= event.relative / graph_edit.zoom
			graph_edit.accept_event()
