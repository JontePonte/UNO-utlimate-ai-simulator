extends Node

func _ready():
	print("=== PlayerView Move History Test Start ===")
	run_test()
	print("=== PlayerView Move History Test End ===")


func run_test():
	# --- Skapa spelare ---
	var p1 = Player.new(0)
	var p2 = Player.new(1)
	
	# Lägg till kort i händerna
	p1.hand.append(Card.new(Card.CardColor.RED, Card.CardValue.FIVE))
	p2.hand.append(Card.new(Card.CardColor.BLUE, Card.CardValue.SEVEN))
	
	# Skapa UnoGame
	var game = UnoGame.new([p1, p2])
	
	# --- Simulera några drag ---
	game.play_card(0, p1.hand[0])    # Spelare 0 spelar
	game.draw_cards(1, 1)            # Spelare 1 drar ett kort
	game.pass_turn(1)                # Spelare 1 passerar
	
	# --- Skapa PlayerView för båda spelare ---
	var view_p1 = game.create_player_view(0)
	var view_p2 = game.create_player_view(1)
	
	# --- Kontrollera att move_history är korrekt duplicerad ---
	print("--- Player 0 Move History (View) ---")
	for move in view_p1.move_history:
		var card_str: String
		if move.card != null:
			card_str = move.card.card_to_string()
		else:
			card_str = "None"
		print("PlayerIndex:", move.player_index,
			  " Type:", move_type_to_string(move.move_type),
			  " Card:", card_str,
			  " DeclaredColor:", card_color_to_string(move.declared_color),
			  " TurnNumber:", move.turn_number)

	print("--- Player 1 Move History (View) ---")
	for move in view_p2.move_history:
		var card_str: String
		if move.card != null:
			card_str = move.card.card_to_string()
		else:
			card_str = "None"
		print("PlayerIndex:", move.player_index,
			  " Type:", move_type_to_string(move.move_type),
			  " Card:", card_str,
			  " DeclaredColor:", card_color_to_string(move.declared_color),
			  " TurnNumber:", move.turn_number)

	# --- Modifiera view och kolla att original GameState ej påverkas ---
	view_p1.move_history.clear()
	print("After clearing view_p1 move_history, GameState move_history size:", game.state.move_history.size())


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
