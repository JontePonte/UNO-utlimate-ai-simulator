extends Node

func _ready():
	var red_5 = Card.new(Card.CardColor.RED, Card.CardValue.FIVE)
	var blue_5 = Card.new(Card.CardColor.BLUE, Card.CardValue.FIVE)
	var green_7 = Card.new(Card.CardColor.GREEN, Card.CardValue.SEVEN)
	var wild_card = Card.new(Card.CardColor.WILD, Card.CardValue.WILD)

	print(red_5.card_to_string(), " on ", blue_5.card_to_string(), " => ", red_5.is_playable_on(blue_5)) # true (value)
	print(green_7.card_to_string(), " on ", blue_5.card_to_string(), " => ", green_7.is_playable_on(blue_5)) # false
	print(wild_card.card_to_string(), " on ", green_7.card_to_string(), " => ", wild_card.is_playable_on(green_7)) # true
