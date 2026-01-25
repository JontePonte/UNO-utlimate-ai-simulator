class_name Deck

var cards: Array[Card] = []

func shuffle():
	cards.shuffle()

func draw() -> Card:
	if cards.is_empty():
		return null
	return cards.pop_back()
