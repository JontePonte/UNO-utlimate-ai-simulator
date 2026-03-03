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
	print("First discard:", card.card_to_string())

func next_player():
	var num_players = state.players.size()
	state.current_player_index = (state.current_player_index + state.play_direction + num_players) % num_players
	return state.players[state.current_player_index]

func play_card(player: Player, card: Card) -> bool:
	var top_card = state.discard_pile[-1]
	
	if not card.is_playable_on(top_card):
		print("Card not playable:", card.card_to_string())
		return false

	# Remove card from player's hand
	player.hand.erase(card)
	state.discard_pile.append(card)
	print("%s played %s" % [player.id, card.card_to_string()])

	# Handle special cards
	match card.value:
		Card.CardValue.SKIP:
			next_player()  # skip next player
		Card.CardValue.REVERSE:
			state.play_direction *= -1
		Card.CardValue.DRAW_TWO:
			var next_p = next_player()
			draw_cards(next_p, 2)
		Card.CardValue.WILD_DRAW_FOUR:
			var next_p = next_player()
			draw_cards(next_p, 4)
		_:
			pass

	# Move to next player normally
	next_player()
	return true

func draw_cards(player: Player, amount: int):
	for i in range(amount):
		var card = state.draw_pile.draw()
		if card != null:
			player.hand.append(card)
		else:
			print("Draw pile empty!")

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
		state.turn_number
	)
