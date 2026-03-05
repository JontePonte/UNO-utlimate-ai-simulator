extends Control

@onready var bottom_hand = $BottomHand
@onready var top_hand = $TopHand
@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand

# Hur många pixlar från skärmens kant händerna ska ligga
@export var edge_margin: float = 30.0 

func _ready():
	# Vänta en frame så Godot hinner rita upp fönstret och händerna
	# (Annars kan deras 'size' vara 0 när vi försöker mäta dem)
	await get_tree().process_frame
	
	_update_layout()
	
	# Magi: Lyssna på om fönstret ändrar storlek under spelets gång!
	get_tree().root.size_changed.connect(_update_layout)

func _update_layout():
	# Hämta skärmens exakta storlek i pixlar just nu
	var screen_size = get_viewport_rect().size
	var center = screen_size / 2.0
	
	# 1. Centrera rotationspunkten (Pivot) på alla händer
	_set_center_pivot(bottom_hand)
	_set_center_pivot(top_hand)
	_set_center_pivot(left_hand)
	_set_center_pivot(right_hand)

	# 2. Placera ut och rotera! 
	# (Vi drar av halva handens storlek så de centreras exakt på koordinaten)
	
	# Botten (Människan) - Rakt upp
	bottom_hand.position = Vector2(center.x - bottom_hand.size.x / 2.0, screen_size.y - edge_margin - bottom_hand.size.y / 2.0)
	bottom_hand.rotation_degrees = 0
	
	# Toppen (Motspelare mittemot) - Upp och ner
	top_hand.position = Vector2(center.x - top_hand.size.x / 2.0, edge_margin - top_hand.size.y / 2.0)
	top_hand.rotation_degrees = 180
	
	# Vänster (Snurrad 90 grader medurs)
	left_hand.position = Vector2(edge_margin - left_hand.size.x / 2.0, center.y - left_hand.size.y / 2.0)
	left_hand.rotation_degrees = 90
	
	# Höger (Snurrad 90 grader moturs)
	right_hand.position = Vector2(screen_size.x - edge_margin - right_hand.size.x / 2.0, center.y - right_hand.size.y / 2.0)
	right_hand.rotation_degrees = -90


func _set_center_pivot(control_node: Control):
	# Flyttar nodens "gångjärn" till exakt mitten av dess bredd och höjd
	control_node.pivot_offset = control_node.size / 2.0
