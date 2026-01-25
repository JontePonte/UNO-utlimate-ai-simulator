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
