extends Control

# Dra in din root_node.tscn hit i Inspektorn i Godot!
@export var root_node_scene: PackedScene 

@onready var back_button = $MarginContainer/HBoxContainer/BackToMenuButton
# Se till att denna stämmer med vad din GraphEdit-nod heter i trädet!
@onready var graph_edit = $GraphEdit 

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
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
