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

func next_player():
	var num_players = state.players.size()
	state.current_player_index = (state.current_player_index + state.play_direction + num_players) % num_players
	return state.current_player_index


# --- PLAYER ACTIONS ---

func play_card(player_index: int, card: Card, declared_color: Card.CardColor = Card.CardColor.RED) -> bool:
	var player = state.players[player_index]
	var top_card = state.discard_pile[-1]
	
	if not card.is_playable_on(top_card):
		# Kort kan inte spelas
		return false

	# Ta bort kort från hand
	player.hand.erase(card)
	state.discard_pile.append(card)

	# Hantera specialkort
	match card.value:
		Card.CardValue.SKIP:
			next_player()  # skip next player
		Card.CardValue.REVERSE:
			state.play_direction *= -1
		Card.CardValue.DRAW_TWO:
			var next_p_index = next_player()
			draw_cards(next_p_index, 2)
		Card.CardValue.WILD_DRAW_FOUR:
			var next_p_index = next_player()
			draw_cards(next_p_index, 4)
		_:
			pass

	# Logga draget
	_log_move(player_index, Move.MoveType.PLAY_CARD, card, declared_color)

	# Gå till nästa spelare
	next_player()
	return true


func draw_cards(player_index: int, amount: int = 1):
	var player = state.players[player_index]
	for i in range(amount):
		var card = state.draw_pile.draw()
		if card != null:
			player.hand.append(card)
			_log_move(player_index, Move.MoveType.DRAW_CARD, card)
		else:
			# Draw pile empty
			pass


func pass_turn(player_index: int):
	_log_move(player_index, Move.MoveType.PASS)
	next_player()


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
	
	return PlayerView.new(
		player_index,
		player.hand.duplicate(),
		top_card,
		card_counts.duplicate(),
		state.current_player_index,
		state.play_direction,
		state.turn_number,
		state.move_history.duplicate()
	)
