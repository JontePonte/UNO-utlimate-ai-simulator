class_name SimulationManager
extends RefCounted # <-- OBS! Vi använder RefCounted istället för Node. Det gör den blixtsnabb eftersom den inte belastar Godots scen-träd överhuvudtaget!

var state: GameState
var rules: Rules
var START_CARD_AMOUNT = 7

func _init(_players: Array[Player], _rules := Rules.new()):
	state = GameState.new()
	state.players = _players
	rules = _rules

	state.draw_pile = Deck.new()
	state.draw_pile.shuffle()
	state.discard_pile = []

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
	while card.color == Card.CardColor.WILD:
		state.draw_pile.cards.append(card)
		state.draw_pile.shuffle()
		card = state.draw_pile.draw()

	state.discard_pile.append(card)
	state.current_color = card.color

# --- TURN MANAGEMENT (Nu blixtsnabb!) ---
func process_turn():
	var player = state.players[state.current_player_index]
	var player_view = create_player_view(state.current_player_index)
	
	var action = await player.take_turn(player_view)
	
	if action != null and action.card != null:
		play_card(state.current_player_index, action.card, action.declared_color)
	else:
		draw_cards(state.current_player_index, 1)
		var drawn_card = player.hand[-1]
		var top_card = state.discard_pile[-1]
		
		# Spela det dragna kortet om möjligt
		if drawn_card.is_playable_on(top_card, state.current_color):
			var color_to_use = drawn_card.color
			if color_to_use == Card.CardColor.WILD:
				color_to_use = [Card.CardColor.RED, Card.CardColor.BLUE, Card.CardColor.GREEN, Card.CardColor.YELLOW].pick_random()
			play_card(state.current_player_index, drawn_card, color_to_use)
	
	# Gå vidare till nästa
	next_player()
	state.turn_number += 1

func next_player():
	var steps = 1
	if state.pending_skip:
		steps = 2
		state.pending_skip = false
		
	var num_players = state.players.size()
	state.current_player_index = (state.current_player_index + (state.play_direction * steps) + num_players) % num_players

# --- KÖR MATCHEN OCH RETURNERA RESULTATET ---
func run_match(max_turns: int = 1000) -> Dictionary:
	var turn_count = 0
	
	while turn_count < max_turns:
		await process_turn()
		
		# Kolla om någon vann
		for p in state.players:
			if p.hand.size() == 0:
				return {
					"winner_name": p.name,
					"winner_index": state.players.find(p),
					"turns_played": turn_count,
					"reason": "Win"
				}
		turn_count += 1
		
	# Om loopen tar slut utan vinnare
	return {
		"winner_name": "Draw",
		"winner_index": -1,
		"turns_played": max_turns,
		"reason": "Max Turns Reached"
	}

# --- PLAYER ACTIONS ---
func play_card(player_index: int, card: Card, declared_color: Card.CardColor = Card.CardColor.RED) -> bool:
	var player = state.players[player_index]
	
	player.hand.erase(card)
	state.discard_pile.append(card)

	if card.color == Card.CardColor.WILD:
		state.current_color = declared_color
	else:
		state.current_color = card.color
	
	_log_move(player_index, Move.MoveType.PLAY_CARD, card, declared_color)
	
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

func get_next_player_index_simple(steps: int) -> int:
	var num_players = state.players.size()
	return (state.current_player_index + (state.play_direction * steps) + num_players) % num_players

func draw_cards(player_index: int, amount: int = 1):
	var player = state.players[player_index]
	for i in range(amount):
		if state.draw_pile.cards.size() == 0:
			_reshuffle_discard_into_draw()
			
		var card = state.draw_pile.draw()
		if card != null:
			player.hand.append(card)
			_log_move(player_index, Move.MoveType.DRAW_CARD, card)

func _reshuffle_discard_into_draw():
	var top_card = state.discard_pile.pop_back()
	state.draw_pile.cards.append_array(state.discard_pile)
	state.discard_pile.clear()
	state.draw_pile.shuffle()
	if top_card != null:
		state.discard_pile.append(top_card)

func _log_move(player_index: int, move_type: Move.MoveType, card: Card = null, declared_color: Card.CardColor = Card.CardColor.RED):
	var move = Move.new(player_index, move_type, card, declared_color, state.turn_number)
	state.move_history.append(move)

func create_player_view(player_index: int) -> PlayerView:
	var player = state.players[player_index]
	var top_card = state.discard_pile[-1]
	var card_counts: Array[int] = []
	for p in state.players:
		card_counts.append(p.hand.size())
	
	return PlayerView.new(
		player_index, player.hand.duplicate(), top_card, state.current_color, 
		card_counts.duplicate(), state.current_player_index, state.play_direction, 
		state.turn_number, state.move_history.duplicate()
	)

func save_debug_log(filename: String = "res://debug_match_log.txt"):
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file == null:
		print("Kunde inte skapa loggfil!")
		return
		
	file.store_line("=== DEBUG LOGG FÖR MATCH ===")
	file.store_line("Antal spelare: " + str(state.players.size()))
	
	# Gör om färg-ID till text (t.ex. "RED" eller "BLUE")
	var start_color_name = Card.CardColor.keys()[state.current_color]
	file.store_line("Startfärg: " + start_color_name)
	file.store_line("----------------------------\n")
	
	for move in state.move_history:
		var p_name = state.players[move.player_index].name
		var action_text = ""
		
		if move.move_type == Move.MoveType.PLAY_CARD:
			# Här använder vi din grymma inbyggda funktion!
			action_text = "spelade " + move.card.card_to_string()
			
			if move.card.color == Card.CardColor.WILD:
				var chosen_color_name = Card.CardColor.keys()[move.declared_color]
				action_text += " (Valde ny färg: " + chosen_color_name + ")"
		
		elif move.move_type == Move.MoveType.DRAW_CARD:
			if move.card != null:
				# Nu kan vi till och med se exakt vilket kort de drog!
				action_text = "drog " + move.card.card_to_string()
			else:
				action_text = "försökte dra ett kort, men leken var tom"
			
		elif move.move_type == Move.MoveType.PASS:
			action_text = "passade"
			
		var line = "Tur " + str(move.turn_number) + " | " + p_name + " " + action_text
		file.store_line(line)
		
	file.store_line("\n=== SLUT PÅ MATCH ===")
	file.close()
	
	print("Logg sparad till: ", ProjectSettings.globalize_path(filename))
