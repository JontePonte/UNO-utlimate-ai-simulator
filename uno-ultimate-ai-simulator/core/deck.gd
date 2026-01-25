class_name Deck

var cards: Array[Card] = []

func _init():
	build_standard_uno_deck()
	shuffle()

func build_standard_uno_deck():
	cards.clear()

	var colors = [
		Card.CardColor.RED,
		Card.CardColor.GREEN,
		Card.CardColor.BLUE,
		Card.CardColor.YELLOW
	]

	for color in colors:
		# One zero
		cards.append(Card.new(color, Card.CardValue.ZERO))

		# Two of each 1–9
		for value in [
			Card.CardValue.ONE, Card.CardValue.TWO, Card.CardValue.THREE,
			Card.CardValue.FOUR, Card.CardValue.FIVE, Card.CardValue.SIX,
			Card.CardValue.SEVEN, Card.CardValue.EIGHT, Card.CardValue.NINE
		]:
			cards.append(Card.new(color, value))
			cards.append(Card.new(color, value))

		# Two of each action card
		for action in [
			Card.CardValue.SKIP,
			Card.CardValue.REVERSE,
			Card.CardValue.DRAW_TWO
		]:
			cards.append(Card.new(color, action))
			cards.append(Card.new(color, action))

	# Wild cards (color = WILD)
	for i in range(4):
		cards.append(Card.new(Card.CardColor.WILD, Card.CardValue.WILD))
		cards.append(Card.new(Card.CardColor.WILD, Card.CardValue.WILD_DRAW_FOUR))

func shuffle():
	cards.shuffle()

func draw() -> Card:
	if cards.is_empty():
		return null
	return cards.pop_back()

func size() -> int:
	return cards.size()
