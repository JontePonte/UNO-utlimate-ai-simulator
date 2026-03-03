class_name Card

enum CardColor {
	RED,
	GREEN,
	BLUE,
	YELLOW,
	WILD
}

enum CardValue {
	ZERO,
	ONE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	SKIP,
	REVERSE,
	DRAW_TWO,
	WILD,
	WILD_DRAW_FOUR
}

var color: CardColor
var value: CardValue


func _init(_color: CardColor, _value: CardValue):
	color = _color
	value = _value


func is_playable_on(top_card: Card, active_color: Card.CardColor) -> bool:
	# Wild-kort får (nästan) alltid spelas
	if color == CardColor.WILD:
		return true
		
	# Matchar den gällande färgen? (Detta löser problemet när en Wild ligger överst!)
	if color == active_color:
		return true
		
	# Matchar valören? (T.ex. röd 7:a på blå 7:a)
	if value == top_card.value:
		return true
		
	return false


func card_to_string() -> String:
	return str(CardColor.keys()[color]) + " " + str(CardValue.keys()[value])
