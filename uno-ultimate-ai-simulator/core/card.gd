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


func is_playable_on(other: Card) -> bool:
	if color == CardColor.WILD:
		return true
	
	if other.color == CardColor.WILD:
		return true
	
	if color == other.color:
		return true
	
	if value == other.value:
		return true
	
	return false


func card_to_string() -> String:
	return str(CardColor.keys()[color]) + " " + str(CardValue.keys()[value])
