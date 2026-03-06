extends Control

@onready var bottom_hand = $BottomHand
@onready var top_hand = $TopHand
@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand

@export var card_ui_scene: PackedScene

@onready var draw_pile_node = $Table/DrawPile
@onready var discard_pile_node = $Table/DiscardPile

@onready var turn_arrow = $TurnArrow

# En ordbok som översätter spelets färger till riktiga färgkoder!
const UNO_COLORS = {
	Card.CardColor.RED: Color(0.9, 0.2, 0.2),
	Card.CardColor.BLUE: Color(0.2, 0.4, 0.9),
	Card.CardColor.GREEN: Color(0.2, 0.8, 0.2),
	Card.CardColor.YELLOW: Color(0.9, 0.8, 0.2),
	Card.CardColor.WILD: Color(1.0, 1.0, 1.0)
}

var last_player_index: int = -1

# --- SPELETS LOGIK ---
var game_manager: GameManager
var player_uis: Array[PlayerHandUI] = []

# Hur många pixlar från skärmens kant händerna ska ligga
@export var edge_margin: float = 100.0 

func _ready():
	await get_tree().process_frame
	
	# Lägg in händerna i en lista så plats 0 = bottom, plats 1 = left, osv.
	player_uis = [bottom_hand, left_hand, top_hand, right_hand]
	
	_update_layout()
	
	# _test_piles() 
	
	start_real_game()

func _update_layout():
	var screen_size = get_viewport_rect().size
	var center = screen_size / 2.0
	
# --- 1. SÄTT DYNAMISK STORLEK (NYTT OCH SÄKERT!) ---
	# Händerna får max ta upp X% av skärmens längd åt sitt håll. 
	# Då lämnar vi trygga tomrum i alla fyra hörn!
	var horizontal_width = screen_size.x * 0.60 
	var vertical_width = screen_size.y * 0.70 
	
	# Höjden på det nedskalade kortet
	var hand_height = 160.0 
	
	bottom_hand.size = Vector2(horizontal_width, hand_height)
	top_hand.size = Vector2(horizontal_width, hand_height)
	
	# Observera att X här är vertical_width, eftersom vi definierar boxen 
	# INNAN vi roterar den 90 grader!
	left_hand.size = Vector2(vertical_width, hand_height)
	right_hand.size = Vector2(vertical_width, hand_height)

	# --- 2. CENTRERA PIVOT ---
	_set_center_pivot(bottom_hand)
	_set_center_pivot(top_hand)
	_set_center_pivot(left_hand)
	_set_center_pivot(right_hand)

	# --- 3. PLACERA OCH ROTERA ---
	# Botten (Människan)
	bottom_hand.position = Vector2(center.x - bottom_hand.size.x / 2.0, screen_size.y - edge_margin - bottom_hand.size.y / 2.0)
	bottom_hand.rotation_degrees = 0
	
	# Toppen 
	top_hand.position = Vector2(center.x - top_hand.size.x / 2.0, edge_margin - top_hand.size.y / 2.0)
	top_hand.rotation_degrees = 180
	
	# Vänster 
	left_hand.position = Vector2(edge_margin - left_hand.size.x / 2.0, center.y - left_hand.size.y / 2.0)
	left_hand.rotation_degrees = 90
	
	# Höger 
	right_hand.position = Vector2(screen_size.x - edge_margin - right_hand.size.x / 2.0, center.y - right_hand.size.y / 2.0)
	right_hand.rotation_degrees = -90


func _set_center_pivot(control_node: Control):
	# Flyttar nodens "gångjärn" till exakt mitten av dess bredd och höjd
	control_node.pivot_offset = control_node.size / 2.0


# --- BARA FÖR TEST ---
func _test_piles():
	# 1. Bygg Plockhögen (Draw Pile)
	# Vi loopar 108 gånger för att skapa den tjocka leken
	for i in range(108):
		var card = card_ui_scene.instantiate()
		draw_pile_node.add_child(card)
		
		card.set_interactable(false)
		
		# Vänd baksidan uppåt (Eftersom vi inte har anropat set_card_data är kortet 'tomt')
		card.set_face_up(false) 
		
		# Centrera kortet över vår punkt, minus halva dess storlek
		var center_offset = -card.size / 2.0
		
		# Den falska 3D-effekten! Varje kort flyttas 0.3 pixlar snett uppåt vänster
		var depth_offset = Vector2(-i * 0.3, -i * 0.3) 
		
		card.position = center_offset + depth_offset


	# 2. Bygg Kasthögen (Discard Pile)
	# Vi skapar tre låtsaskort för att se stökigheten
	var dummy_discard = [
		Card.new(Card.CardColor.RED, Card.CardValue.FIVE),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.GREEN, Card.CardValue.EIGHT)
	]
	
	for i in range(dummy_discard.size()):
		var card = card_ui_scene.instantiate()
		discard_pile_node.add_child(card)
		
		card.set_interactable(false)
		
		card.set_card_data(dummy_discard[i])
		card.set_face_up(true)
		
		var center_offset = -card.size / 2.0
		
		# Stökigheten! Slumpa fram en liten knuff och rotation
		var randomness_translate = 5
		var randomness_rotate = 7
		var messy_offset = Vector2(randf_range(-randomness_translate, randomness_translate), randf_range(-randomness_translate, randomness_translate))
		card.rotation_degrees = randf_range(-randomness_rotate, randomness_rotate)
		
		card.position = center_offset + messy_offset

func start_real_game():
	# 1. Skapa fyra AI-spelare 
	# (Eftersom vi inte har en HumanPlayer än, låter vi 4 bottar slåss!)
	var players: Array[Player] = [
		Player.new(0, "AI_Botten", false, AISimple.new()), 
		Player.new(1, "AI_Vänster", false, AISimple.new()),
		Player.new(2, "AI_Toppen", false, AISimple.new()),
		Player.new(3, "AI_Höger", false, AISimple.new())
	]
	
	# 2. Skapa hjärnan och lägg till den i trädet (VIKTIGT för att timers ska funka!)
	game_manager = GameManager.new(players)
	add_child(game_manager)
	
	# 3. Slå på spelets "TV-läge"
	game_manager.visual_mode = true
	game_manager.turn_delay = 1.0 # 1 sekund per drag
	
	# 4. Koppla hjärnans signaler till våra ögon (UI)
	game_manager.card_played.connect(_on_card_played)
	game_manager.card_drawn.connect(_on_card_drawn)
	game_manager.turn_started.connect(_on_turn_started)
	
	# 5. Rita upp startläget! (Dela ut kort och visa första kortet i kasthögen)
	update_all_visuals()
	_spawn_discard_card(game_manager.state.discard_pile[-1]) # Det allra första kortet
	
	await get_tree().create_timer(1.5).timeout
	for hand in player_uis:
		hand._adjust_card_spacing()
	
	# 6. STARTA MATCHEN! 
	game_manager.run_full_game()


func update_all_visuals():
	# Synka de fysiska händerna
	for i in range(game_manager.state.players.size()):
		var logical_player = game_manager.state.players[i]
		player_uis[i].update_hand(logical_player.hand)
		
	# Synka plockhögen i mitten
	_update_draw_pile_visual()
	
	# Kolla om hjärnan precis har blandat om kasthögen!
	if discard_pile_node.get_child_count() > game_manager.state.discard_pile.size():
		_cleanup_discard_pile_visual()


# --- SIGNAL MOTTAGARE ---
func _on_card_drawn(_player_index: int, _card: Card):
	# Uppdatera bara händerna när någon drar ett kort
	update_all_visuals()

func _on_card_played(_player_index: int, card: Card, _declared_color: Card.CardColor):
	# 1. Släng kortet i mitten med vår snygga "stökiga" effekt
	_spawn_discard_card(card)
	
	# 2. Uppdatera händerna (så kortet försvinner från spelarens hand)
	update_all_visuals()


# --- VISUELLA HJÄLPARE ---
func _spawn_discard_card(card_data: Card):
	var visual_card = card_ui_scene.instantiate()
	discard_pile_node.add_child(visual_card)
	
	visual_card.set_interactable(false)
	visual_card.set_card_data(card_data)
	visual_card.set_face_up(true)
	
	var center_offset = -visual_card.size / 2.0
	
	# Stökigheten! Slumpa fram en liten knuff och rotation
	var randomness_translate = 5.0
	var randomness_rotate = 7.0
	var messy_offset = Vector2(randf_range(-randomness_translate, randomness_translate), randf_range(-randomness_translate, randomness_translate))
	visual_card.rotation_degrees = randf_range(-randomness_rotate, randomness_rotate)
	
	visual_card.position = center_offset + messy_offset

func _update_draw_pile_visual():
	# 1. Rensa bort den gamla grafiska högen
	for child in draw_pile_node.get_children():
		child.queue_free()
		
	# 2. Kolla hur många kort hjärnan faktiskt har i plockhögen just nu
	var cards_left = game_manager.state.draw_pile.cards.size()
	
	# 3. Bygg upp högen på nytt!
	for i in range(cards_left):
		var visual_card = card_ui_scene.instantiate()
		draw_pile_node.add_child(visual_card)
		
		visual_card.set_interactable(false)
		visual_card.set_face_up(false) 
		
		var center_offset = -visual_card.size / 2.0
		# Tätare mellanrum (0.2) så en lek med 80 kort inte blir onaturligt hög
		var depth_offset = Vector2(-i * 0.2, -i * 0.2) 
		
		visual_card.position = center_offset + depth_offset

func _cleanup_discard_pile_visual():
	# 1. Radera alla grafiska kort i den stökiga högen
	for child in discard_pile_node.get_children():
		child.queue_free()
		
	# 2. Lägg tillbaka det enda kortet som hjärnan sparade
	if game_manager.state.discard_pile.size() > 0:
		var top_card = game_manager.state.discard_pile[-1]
		_spawn_discard_card(top_card)

func _on_turn_started(current_player_index: int):
	var current_color = game_manager.state.current_color
	var direction = game_manager.state.play_direction
	var num_players = game_manager.state.players.size()
	
	# 1. Tänd den aktiva spelaren, släck de andra
	for i in range(player_uis.size()):
		player_uis[i].set_active(i == current_player_index)
		
	# 2. Om det är allra första draget sätter vi bara startspelaren och avbryter
	if last_player_index == -1:
		last_player_index = current_player_index
		turn_arrow.hide() # Göm pilen tills det faktiskt sker ett drag
		return
		
	turn_arrow.show()
	
	# 3. Kalkylera om någon blev överhoppad (Den matematiska magin!)
	var expected_next = (last_player_index + direction + num_players) % num_players
	if expected_next != current_player_index:
		# Någon blev överhoppad! Peka på dem och visa skip-symbolen
		player_uis[expected_next].show_skip_animation(UNO_COLORS[current_color])
		
	# 4. Flytta och rotera pilen
	# (Se till att dina Marker2D heter exakt "AnchorCW" och "AnchorCCW")
	var anchor_name = "AnchorCW" if direction == 1 else "AnchorCCW"
	var start_node = player_uis[last_player_index].get_node(anchor_name)
	
	# Pilen utgår från förra spelarens ankare
	turn_arrow.global_position = start_node.global_position
	
	# Pilen tittar rakt på den nya spelarens hand-centrum
	turn_arrow.look_at(player_uis[current_player_index].global_position)
	
	# Färga pilen
	turn_arrow.modulate = UNO_COLORS[current_color]
	
	# Spara vem som fick turen till nästa gång
	last_player_index = current_player_index
