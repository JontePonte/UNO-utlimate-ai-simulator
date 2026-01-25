extends Node

func _ready():
	var deck = Deck.new()
	print("Deck size:", deck.size())
	print("----------------------------")

	var index = 1
	while deck.size() > 0:
		var card = deck.draw()
		print("%d: %s" % [index, card.card_to_string()])
		index += 1
