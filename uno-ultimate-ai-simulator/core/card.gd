class_name Card

enum CardColor { RED, GREEN, BLUE, YELLOW, WILD }
enum CardValue {
	ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE,
	SKIP, REVERSE, DRAW_TWO, WILD, WILD_DRAW_FOUR
}

var color: CardColor
var value: CardValue

func _init(_color: CardColor, _value: CardValue):
	color = _color
	value = _value
