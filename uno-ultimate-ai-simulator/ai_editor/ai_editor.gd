extends Control

@export var root_node_scene: PackedScene
@export var action_draw_node_scene: PackedScene

@onready var back_button = $MarginContainer/HBoxContainer/BackToMenuButton
@onready var graph_edit = $GraphEdit
@onready var context_menu = $GraphContextMenu
@onready var node_context_menu = $NodeContextMenu

var right_click_position: Vector2 = Vector2.ZERO
var node_to_edit: GraphNode = null

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	context_menu.add_item("Action: Draw Card", 0)
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	
	# Lyssna på när GraphEdit ber om en högerklicksmeny (popup_request)
	graph_edit.popup_request.connect(_on_graph_edit_popup_request)
	
	# Sätt upp vår nya nod-meny
	node_context_menu.add_item("Copy Node", 0)
	node_context_menu.add_item("Remove Node", 1)
	node_context_menu.id_pressed.connect(_on_node_context_menu_id_pressed)
	
	if AiManager.file_to_edit != "":
		print("Laddar AI: ", AiManager.file_to_edit)
		_load_ai_graph(AiManager.file_to_edit)
	else:
		print("Ingen fil angiven, något blev fel i övergången.")

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
	root.position_offset = Vector2(40, 40) # Lägger noden nära övre vänstra hörnet
	
	root.gui_input.connect(_on_node_gui_input.bind(root))
	
	# (Senare ska vi lägga in kod här som läser JSON-filen 
	# och lägger ut alla andra noder eleven har byggt!)
	print("Förbereder GraphEdit för att senare läsa in: ", file_name)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://menus/CreateAndEditMenu.tscn")

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

func _on_node_gui_input(event: InputEvent, node: GraphNode):
	# Koll om det är ett högerklick!
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		node.accept_event()
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
