extends Control

@export var root_node_scene: PackedScene
@export var action_draw_node_scene: PackedScene

@onready var back_button = $MarginContainer/HBoxContainer/BackToMenuButton
@onready var graph_edit = $GraphEdit
@onready var context_menu = $GraphContextMenu

var right_click_position: Vector2 = Vector2.ZERO

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Vi lägger till ett val i menyn. "0" är ID-numret för detta val.
	context_menu.add_item("Action: Draw Card", 0)
	
	# Lyssna på när menyn klickas på
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	
	# Lyssna på när GraphEdit ber om en högerklicksmeny (popup_request)
	graph_edit.popup_request.connect(_on_graph_edit_popup_request)
	
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
	if id == 0: # 0 var ID:t vi gav till "Action: Draw Card"
		var new_node = action_draw_node_scene.instantiate()
		graph_edit.add_child(new_node)
		
		# Placera noden exakt där vi högerklickade!
		# Eftersom GraphEdit kan vara inzoomad/skrollad måste vi justera positionen lite:
		var scroll_offset = graph_edit.scroll_offset
		new_node.position_offset = right_click_position + scroll_offset
