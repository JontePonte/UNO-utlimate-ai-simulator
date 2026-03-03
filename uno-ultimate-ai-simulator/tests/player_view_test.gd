extends Node

func _ready():
	print("=== PlayerView Test Start ===")
	
	test_player_view_creation()
	test_array_is_duplicated()
	
	print("=== PlayerView Test End ===")


# --- Test 1: Kontrollera att PlayerView skapas korrekt ---
func test_player_view_creation():
	print("\n-- test_player_view_creation --")
	
	# Skapa två spelare
	var p1 = Player.new(0)
	var p2 = Player.new(1)
	
	# Lägg till ett manuellt kort i handen (kommer kombineras med UnoGame deal)
	p1.hand.append(Card.new(Card.CardColor.RED, Card.CardValue.FIVE))
	p2.hand.append(Card.new(Card.CardColor.BLUE, Card.CardValue.SEVEN))
	
	var players: Array[Player] = [p1, p2]
	
	# Skapa UnoGame (initial deal: 7 kort per spelare)
	var game = UnoGame.new(players)
	
	# Ställ in lite game state
	game.state.current_player_index = 0
	game.state.play_direction = 1
	game.state.turn_number = 3
	
	# Lägg till ett Move i history
	var move = Move.new(
		0,
		Move.MoveType.PLAY_CARD,
		p1.hand[0],  # referens till första kortet i hand
		Card.CardColor.RED,
		2
	)
	game.state.move_history.append(move)
	
	# Skapa PlayerView för p1
	var view = game.create_player_view(0)
	
	# Manual assertions med print
	print("Own hand size:", view.own_hand.size(), " (expected 8)") # 1 manuellt + 7 deal
	print("Top discard:", view.top_discard.card_to_string())
	print("Opponent card counts:", view.opponent_card_counts, " (expected [8, 8])")
	print("Move history size:", view.move_history.size(), " (expected 1)")


# --- Test 2: Kontrollera att arrays är duplicerade ---
func test_array_is_duplicated():
	print("\n-- test_array_is_duplicated --")
	
	var p1 = Player.new(0)
	var p2 = Player.new(1)
	
	p1.hand.append(Card.new(Card.CardColor.GREEN, Card.CardValue.ONE))
	p2.hand.append(Card.new(Card.CardColor.YELLOW, Card.CardValue.TWO))
	
	var game = UnoGame.new([p1, p2])
	
	# Skapa PlayerView för p1
	var view = game.create_player_view(0)
	
	# Modifiera view-arrayer
	view.own_hand.clear()
	view.opponent_card_counts.clear()
	view.move_history.clear()
	
	# Kontrollera att original arrays i GameState inte påverkas
	print("Original hand size after modifying view:",
		p1.hand.size(), " (expected 8)")  # 1 manuellt + 7 deal
	print("Original move history size:",
		game.state.move_history.size(), " (expected 0)")
