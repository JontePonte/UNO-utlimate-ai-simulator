extends Control

@export var root_node_scene: PackedScene
@export var action_draw_node_scene: PackedScene
@export var condition_hand_node_scene: PackedScene
@export var action_play_node_scene: PackedScene

@onready var back_button = $MarginContainer/HBoxContainer/BackToMenuButton
@onready var save_button = $MarginContainer/HBoxContainer/SaveButton
@onready var rename_button = $MarginContainer/HBoxContainer/RenameButton
@onready var graph_edit = $GraphEdit
@onready var context_menu = $GraphContextMenu
@onready var node_context_menu = $NodeContextMenu

var right_click_position: Vector2 = Vector2.ZERO
var node_to_edit: GraphNode = null

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	rename_button.pressed.connect(_on_rename_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	
	context_menu.add_item("Action: Draw Card", 0)
	context_menu.add_item("Action: Play Card", 1)
	context_menu.add_item("Condition: Check Hand", 2)
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	
	# Lyssna på när GraphEdit ber om en högerklicksmeny (popup_request)
	graph_edit.popup_request.connect(_on_graph_edit_popup_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	
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

# Den här funktionen kommer bygga hela trädet framöver
func _load_ai_graph(file_name: String):
	# 1. Rensa hela duken ifall det låg gammalt skräp där
	graph_edit.clear_connections()
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.queue_free()
			
	# 2. Skapa vår Root Node!
	var root = root_node_scene.instantiate()
	graph_edit.add_child(root)
	
	# 3. Placera den snyggt på vänster sida av duken (X=100, Y=200)
	graph_edit.scroll_offset = Vector2.ZERO # Tvingar kameran till startpunkten
	root.position_offset = Vector2(40, 320)
	
	root.gui_input.connect(_on_node_gui_input.bind(root))
	
	# (Senare ska vi lägga in kod här som läser JSON-filen 
	# och lägger ut alla andra noder eleven har byggt!)
	print("Förbereder GraphEdit för att senare läsa in: ", file_name)

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	# Godkänn sladden och be GraphEdit att rita den permanent!
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	# Ta bort sladden om användaren kopplar loss den
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://menus/CreateAndEditAI.tscn")

func _on_graph_edit_popup_request(p_position: Vector2):
	# Spara positionen där musen är just nu
	right_click_position = p_position
	
	# Flytta menyn till musens position och visa den!
	# p_position är musens position relativt till skärmen, så vi använder get_screen_position() + p_position
	context_menu.position = Vector2i(get_viewport().get_mouse_position())
	context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	if id == 0:
		var new_node = action_draw_node_scene.instantiate()
		graph_edit.add_child(new_node)
		
		var scroll_offset = graph_edit.scroll_offset
		new_node.position_offset = right_click_position + scroll_offset
		
		# NYTT: Säg åt den nya noden att lyssna på musklick!
		new_node.gui_input.connect(_on_node_gui_input.bind(new_node))
	if id == 1:
		var new_node = action_play_node_scene.instantiate()
		graph_edit.add_child(new_node)
		
		var scroll_offset = graph_edit.scroll_offset
		new_node.position_offset = right_click_position + scroll_offset
		
		new_node.gui_input.connect(_on_node_gui_input.bind(new_node))
	if id == 2:
		var new_node = condition_hand_node_scene.instantiate()
		graph_edit.add_child(new_node)
		
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
		node_to_delete.queue_free()

func _on_rename_button_pressed():
	print("Här ska vi fixa rename")

func _on_save_button_pressed():
	print("Nu ska vi spara filen: ", AiManager.file_to_edit)
	# (Här ska vi snart skriva logiken för att läsa av duken!)
