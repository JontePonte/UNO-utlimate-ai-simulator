extends Control

@export var root_node_scene: PackedScene
@export var action_draw_node_scene: PackedScene
@export var condition_hand_node_scene: PackedScene
@export var action_play_node_scene: PackedScene

@onready var back_button = $MarginContainer/HBoxContainer/BackToMenuButton
@onready var save_button = $MarginContainer/HBoxContainer/SaveButton
@onready var rename_button = $MarginContainer/HBoxContainer/RenameButton
@onready var test_button = $MarginContainer/HBoxContainer/TestButton
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
	back_button.pressed.connect(_on_back_button_pressed)
	rename_button.pressed.connect(_on_rename_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	test_button.pressed.connect(_on_test_button_pressed)
	
	context_menu.add_item("Action: Draw Card", 0)
	context_menu.add_item("Action: Play Card", 1)
	context_menu.add_item("Condition: Check Hand", 2)
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

func _on_context_menu_id_pressed(id: int):
	_mark_unsaved()
	if id == 0:
		var new_node = action_draw_node_scene.instantiate()
		graph_edit.add_child(new_node)
		new_node.dragged.connect(_mark_unsaved.unbind(2))
		
		var scroll_offset = graph_edit.scroll_offset
		new_node.position_offset = right_click_position + scroll_offset
		
		# NYTT: Säg åt den nya noden att lyssna på musklick!
		new_node.gui_input.connect(_on_node_gui_input.bind(new_node))
	if id == 1:
		var new_node = action_play_node_scene.instantiate()
		graph_edit.add_child(new_node)
		new_node.dragged.connect(_mark_unsaved.unbind(2))
		
		var scroll_offset = graph_edit.scroll_offset
		new_node.position_offset = right_click_position + scroll_offset
		
		new_node.gui_input.connect(_on_node_gui_input.bind(new_node))
	if id == 2:
		var new_node = condition_hand_node_scene.instantiate()
		graph_edit.add_child(new_node)
		new_node.dragged.connect(_mark_unsaved.unbind(2))
		
		var scroll_offset = graph_edit.scroll_offset
		new_node.position_offset = right_click_position + scroll_offset
		
		new_node.gui_input.connect(_on_node_gui_input.bind(new_node))

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
	
	# 1. SPARA ALLA SLADDAR (Godot gör det superenkelt för oss)
	var all_connections = graph_edit.get_connection_list()
	for conn in all_connections:
		save_data["visual_data"]["connections"].append({
			"from_node": String(conn["from_node"]),
			"from_port": conn["from_port"],
			"to_node": String(conn["to_node"]),
			"to_port": conn["to_port"]
		})
	
	# 2. SPARA ALLA NODER
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node_info = {
				"name": child.name, # Godots interna namn (viktigt för sladdarna)
				"title": child.title, # Berättar för oss vilken TYP av nod det är
				"pos_x": child.position_offset.x,
				"pos_y": child.position_offset.y
			}
			
			# Har denna nod en dropdown-meny (OptionButton)? I så fall, spara vad som är valt!
			if child.has_node("OptionButton"):
				var dropdown = child.get_node("OptionButton")
				node_info["selected_index"] = dropdown.selected # Sparar siffran (0, 1, 2...)
				
			save_data["visual_data"]["nodes"].append(node_info)
			
	# 3. SKRIV TILL JSON-FILEN
	var file_path = AiManager.AI_FOLDER_PATH + AiManager.file_to_edit
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		# JSON.stringify formaterar vår Dictionary till snygg text. "\t" ger indrag!
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Sparandet lyckades!")
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
			"Action: Play Card":
				new_node = action_play_node_scene.instantiate()
			"Action: Draw Card":
				new_node = action_draw_node_scene.instantiate()
			_: # Detta körs om ingen av ovanstående matchar!
				print("-> FEL: Titeln '", node_title, "' matchade ingenting! Felstavat?")
				
		if new_node != null:
			new_node.name = node_data["name"]
			new_node.position_offset = Vector2(node_data["pos_x"], node_data["pos_y"])
			graph_edit.add_child(new_node)
			
			new_node.gui_input.connect(_on_node_gui_input.bind(new_node))
			new_node.dragged.connect(_mark_unsaved.unbind(2))
			
			if node_data.has("selected_index") and new_node.has_node("OptionButton"):
				var dropdown = new_node.get_node("OptionButton")
				dropdown.item_selected.connect(func(_idx): _mark_unsaved())
				dropdown.selected = int(node_data["selected_index"])
				
			print("-> Lade till noden: ", new_node.name)
		else:
			print("-> FEL: new_node är null! Är dina @export-scener inlagda i Inspektorn?")

	print("--- BÖRJAR DRA SLADDAR ---")
	# 4. DRA ALLA SLADDAR
	for conn in data["visual_data"]["connections"]:
		var err = graph_edit.connect_node(StringName(conn["from_node"]), conn["from_port"], StringName(conn["to_node"]), conn["to_port"])
		if err != OK:
			print("-> FEL: Kunde inte dra sladd från ", conn["from_node"], " till ", conn["to_node"])
	print("Laddade in AI-trädet framgångsrikt!")

func _on_test_button_pressed():
	# 1. Spara AI:n först så vi testar den senaste versionen!
	_on_save_button_pressed()
	
	# 2. Skapa det flytande fönstret
	var test_window = Window.new()
	test_window.title = "Test Match: " + AiManager.file_to_edit
	test_window.size = Vector2i(1280, 720) 
	test_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	
	# --- RÄTT SKALNINGSMETOD ---
	test_window.content_scale_size = Vector2i(1920, 1080)
	test_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT # <--- Ändrad till VIEWPORT
	test_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	# När man klickar på krysset (X) i fönstret, radera det från minnet
	test_window.close_requested.connect(test_window.queue_free)
	
	# 3. Ladda in din VisualMatch-scen
	var match_scene = load("res://game/VisualMatch.scn").instantiate()
	
	# 4. Lägg in matchen i fönstret, och fönstret i editorn
	test_window.add_child(match_scene)
	add_child(test_window)

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

# Den magiska rekursiva funktionen!
func _build_logic_tree(current_node_name: String) -> Dictionary:
	if current_node_name == "":
		# Om tråden slutar i tomma intet, gör en fallback till "Draw Card"
		return {"type": "action", "name": "draw_card"}
		
	var node = graph_edit.get_node_or_null(NodePath(current_node_name))
	if node == null:
		return {"type": "action", "name": "draw_card"}
		
	var result = {}
	
	# Är det en ACTION-nod?
	if "Action:" in node.title:
		result["type"] = "action"
		
		# Beroende på VILKEN action det är, och vad dropdownen står på:
		if node.title == "Action: Draw Card":
			result["name"] = "draw_card"
		elif node.title == "Action: Play Card":
			var dropdown = node.get_node("OptionButton")
			if dropdown.selected == 0: result["name"] = "play_first_playable"
			elif dropdown.selected == 1: result["name"] = "play_playable_attack_card"
			elif dropdown.selected == 2: result["name"] = "play_color_card" # Bara ett exempel!
			
		return result
		
	# Är det en CONDITION-nod?
	elif "Condition:" in node.title:
		result["type"] = "condition"
		
		var dropdown = node.get_node("OptionButton")
		if dropdown.selected == 0: result["name"] = "can_play_any_card"
		elif dropdown.selected == 1: result["name"] = "has_playable_attack_card"
		# ... (här kan vi lägga till fler matchningar för de andra dropdown-valen senare)
		
		# Nu kommer magin: Vi bygger True och False-grenarna genom att anropa oss själva!
		var true_node_name = _get_connected_node(current_node_name, 0)
		var false_node_name = _get_connected_node(current_node_name, 1)
		
		result["true_branch"] = _build_logic_tree(true_node_name)
		result["false_branch"] = _build_logic_tree(false_node_name)
		
		return result
		
	# Fallback om något går fel
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
