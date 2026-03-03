class_name UnoGame

var state: GameState
var rules: Rules

var START_CARD_AMOUNT = 7

func _init(_players: Array[Player], _rules := Rules.new()):
	state = GameState.new()
	state.players = _players
	rules = _rules

	# Skapa och shuffle deck
	state.draw_pile = Deck.new()
	state.draw_pile.shuffle()

	# Start discard pile
	state.discard_pile = []

	# Initial deal
	deal_initial_hands(START_CARD_AMOUNT)
	start_discard_pile()


func deal_initial_hands(cards_per_player: int):
	for player in state.players:
		for i in range(cards_per_player):
			var card = state.draw_pile.draw()
			if card != null:
				player.hand.append(card)


func start_discard_pile():
	var card = state.draw_pile.draw()
	
	# If first card is WILD_DRAW_FOUR take another
	while card.value == Card.CardValue.WILD_DRAW_FOUR:
		state.draw_pile.cards.append(card)
		state.draw_pile.shuffle()
		card = state.draw_pile.draw()

	state.discard_pile.append(card)
	# Första kortet
	# print("First discard:", card.card_to_string())


# --- TURN MANAGEMENT ---
func process_turn():
	var player = state.players[state.current_player_index]
	var player_view = create_player_view(state.current_player_index)
	
	if player.is_human:
		return 
	elif player.ai_controller != null:
		# Nu får vi tillbaka ett PlayerAction-paket
		var action = player.ai_controller.choose_action(player_view)
		
		# Kolla om paketet innehåller ett kort att spela
		if action != null and action.card != null:
			play_card(state.current_player_index, action.card, action.declared_color)
		else:
			# Om card är null betyder det att vi måste dra ett kort
			draw_cards(state.current_player_index, 1)
	
	next_player()
	state.turn_number += 1

func next_player():
	# Om ett SKIP-kort spelades, hoppar vi ett extra steg
	var steps = 1
	if state.pending_skip:
		steps = 2
		state.pending_skip = false # Återställ flaggan
		
	var num_players = state.players.size()
	state.current_player_index = (state.current_player_index + (state.play_direction * steps) + num_players) % num_players


# Run a full game between AI players for testing
func run_full_game(max_turns: int = 100):
	print("Spelet startar med ", state.players.size(), " spelare.")
	var turn_count = 0
	while turn_count < max_turns:
		var player = state.players[state.current_player_index]
		
		# Logga varje tur
		# print("Tur ", turn_count, ": Spelare ", player.name, "s tur.")
		
		if not player.is_human:
			process_turn()
		
		# Kolla vinstkriterier
		for p in state.players:
			if p.hand.size() == 0:
				print("SPEL SLUT: ", p.name, " vann på tur ", turn_count)
				return
				
		turn_count += 1
	print("Max turns nådda (", max_turns, "). Spelet slutade oavgjort.")

# --- PLAYER ACTIONS ---
func play_card(player_index: int, card: Card, declared_color: Card.CardColor = Card.CardColor.RED) -> bool:
	var player = state.players[player_index]
	
	# (Validering här...)

	player.hand.erase(card)
	state.discard_pile.append(card)

	# FIX: Använd declared_color för att uppdatera spelets färg
	if card.color == Card.CardColor.WILD:
		state.current_color = declared_color
	else:
		state.current_color = card.color
	
	_log_move(player_index, Move.MoveType.PLAY_CARD, card, declared_color) # log before specia-card-print
	match card.value:
		Card.CardValue.SKIP:
			state.pending_skip = true
		Card.CardValue.REVERSE:
			if state.players.size() == 2:
				state.pending_skip = true
			else:
				state.play_direction *= -1
		Card.CardValue.DRAW_TWO:
			var next_idx = get_next_player_index_simple(1)
			draw_cards(next_idx, 2)
			state.pending_skip = true
		Card.CardValue.WILD_DRAW_FOUR:
			var next_idx = get_next_player_index_simple(1)
			draw_cards(next_idx, 4)
			state.pending_skip = true

	return true

# Hjälpfunktion för att titta framåt utan att ändra state
func get_next_player_index_simple(steps: int) -> int:
	var num_players = state.players.size()
	return (state.current_player_index + (state.play_direction * steps) + num_players) % num_players

func draw_cards(player_index: int, amount: int = 1):
	var player = state.players[player_index]
	
	for i in range(amount):
		# Kolla om plockhögen är tom (eller håller på att ta slut)
		if state.draw_pile.cards.size() == 0:
			_reshuffle_discard_into_draw()
			
		var card = state.draw_pile.draw()
		
		if card != null:
			player.hand.append(card)
			_log_move(player_index, Move.MoveType.DRAW_CARD, card)
		else:
			print("Kritiskt fel: Inga kort finns kvar ens efter omblandning!")

# Helpfunction for reshuffle the drawdeck
func _reshuffle_discard_into_draw():
	print("--- Reshuffle discard deck ---") # Avkommentera om du vill se detta i loggen
	
	# Spara det översta kortet i kasthögen
	var top_card = state.discard_pile.pop_back()
	
	# Flytta alla andra kort från kasthögen till plockhögen
	state.draw_pile.cards.append_array(state.discard_pile)
	state.discard_pile.clear()
	
	# Blanda den nya plockhögen
	state.draw_pile.shuffle()
	
	# Lägg tillbaka det översta kortet i kasthögen
	if top_card != null:
		state.discard_pile.append(top_card)


func pass_turn(player_index: int):
	_log_move(player_index, Move.MoveType.PASS)


# --- MOVE LOGGING ---

func _log_move(player_index: int, move_type: Move.MoveType, card: Card = null, declared_color: Card.CardColor = Card.CardColor.RED):
	var move = Move.new(
		player_index,
		move_type,
		card,
		declared_color,
		state.turn_number
	)
	state.move_history.append(move)


# --- PLAYER VIEW ---

func create_player_view(player_index: int) -> PlayerView:
	var player = state.players[player_index]
	var top_card = state.discard_pile[-1]
	
	var card_counts: Array[int] = []
	for p in state.players:
		card_counts.append(p.hand.size())
	
	# Lägg till state.current_color som det fjärde argumentet
	return PlayerView.new(
		player_index,
		player.hand.duplicate(),
		top_card,
		state.current_color, 
		card_counts.duplicate(),
		state.current_player_index,
		state.play_direction,
		state.turn_number,
		state.move_history.duplicate()
	)
