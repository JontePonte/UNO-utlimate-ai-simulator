extends Node

# Ändra denna siffra för att testa med 3, 4, 5 eller fler spelare!
var NUMBER_OF_PLAYERS = 4 

func _ready():
	print("=== Multi-AI Game Test Start ===")
	run_multi_test(NUMBER_OF_PLAYERS)
	print("=== Multi-AI Game Test End ===")


func run_multi_test(player_count: int):
	var players: Array[Player] = []
	
	# --- Skapa rätt antal AI-spelare dynamiskt ---
	for i in range(player_count):
		var ai = AISimple.new()
		var player_name = "AI_" + str(i + 1)
		var p = Player.new(i, player_name, false, ai)
		players.append(p)
	
	# --- Skapa UnoGame med den genererade listan av spelare ---
	var game = GameManager.new(players)
	
	# --- Kör spelet! (Jag höjde max_turns till 500 eftersom fler spelare ofta tar längre tid) ---
	await game.run_full_game(500)
	
	# --- Skriv ut move history ---
	for move in game.state.move_history:
		var card_str: String
		var declared_str: String = ""
		
		if move.card != null:
			card_str = move.card.card_to_string()
			
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
