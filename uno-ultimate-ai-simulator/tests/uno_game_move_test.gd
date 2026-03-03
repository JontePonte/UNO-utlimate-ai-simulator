extends Node

func _ready():
	print("=== UnoGame Move Logging Test Start ===")
	
	run_test()
	
	print("=== UnoGame Move Logging Test End ===")


func run_test():
	# --- Skapa spelare ---
	var p1 = Player.new(0)
	var p2 = Player.new(1)
	
	# Lägg till kort i händerna
	p1.hand.append(Card.new(Card.CardColor.RED, Card.CardValue.FIVE))
	p2.hand.append(Card.new(Card.CardColor.BLUE, Card.CardValue.SEVEN))
	
	var game = UnoGame.new([p1, p2])
	
	# Spela och dra
	game.play_card(0, p1.hand[0])
	game.draw_cards(1, 1)
	game.pass_turn(1)
	
	# --- Print med enum-namn ---
	print("--- Move History ---")
	for move in game.state.move_history:
		var card_str = "None"
		if move.card != null:
			card_str = move.card.card_to_string()
		print("PlayerIndex:", move.player_index,
			  " Type:", move_type_to_string(move.move_type),
			  " Card:", card_str,
			  " DeclaredColor:", card_color_to_string(move.declared_color),
			  " TurnNumber:", move.turn_number)


# --- Hjälpfunktioner för enum → string ---

func move_type_to_string(mt: Move.MoveType) -> String:
	match mt:
		Move.MoveType.PLAY_CARD: return "PLAY_CARD"
		Move.MoveType.DRAW_CARD: return "DRAW_CARD"
		Move.MoveType.PASS: return "PASS"
		_: return "UNKNOWN"

func card_color_to_string(cc: Card.CardColor) -> String:
	match cc:
		Card.CardColor.RED: return "RED"
		Card.CardColor.YELLOW: return "YELLOW"
		Card.CardColor.BLUE: return "BLUE"
		Card.CardColor.GREEN: return "GREEN"
		Card.CardColor.WILD: return "WILD"
		_: return "UNKNOWN"
