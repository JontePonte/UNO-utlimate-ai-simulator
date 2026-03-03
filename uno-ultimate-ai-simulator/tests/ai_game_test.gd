extends Node

func _ready():
	print("=== AI Game Test Start ===")
	run_test()
	print("=== AI Game Test End ===")


func run_test():
	# --- Skapa två AI-spelare ---
	var ai1 = AISimple.new()
	var ai2 = AISimple.new()
	
	var p1 = Player.new(0, "AI_One", false, ai1)
	var p2 = Player.new(1, "AI_Two", false, ai2)
	
	# --- Skapa UnoGame med dessa spelare ---
	var game = UnoGame.new([p1, p2])
	
	# --- Kör ett kort spel, max 200 turer ---
	game.run_full_game(200)
	
	# --- Skriv ut move history för båda spelare ---
	for move in game.state.move_history:
		var card_str: String
		var declared_str: String = "" # Tom sträng som standard
		
		if move.card != null:
			card_str = move.card.card_to_string()
			
			# Lägg bara till DeclaredColor i utskriften om kortet är WILD och det spelades
			if move.move_type == Move.MoveType.PLAY_CARD and move.card.color == Card.CardColor.WILD:
				declared_str = " DeclaredColor: " + card_color_to_string(move.declared_color)
		else:
			card_str = "None"
			
		print("PlayerIndex: ", move.player_index,
			" Type: ", move_type_to_string(move.move_type),
			" Card: ", card_str,
			declared_str,
			" TurnNumber: ", move.turn_number)


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
