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

func color_to_string() -> String:
	match color:
		CardColor.RED: return "Red"
		CardColor.GREEN: return "Green"
		CardColor.BLUE: return "Blue"
		CardColor.YELLOW: return "Yellow"
		CardColor.WILD: return "Wild"
		_: return "Unknown"

func value_to_string() -> String:
	match value:
		CardValue.ZERO: return "0"
		CardValue.ONE: return "1"
		CardValue.TWO: return "2"
		CardValue.THREE: return "3"
		CardValue.FOUR: return "4"
		CardValue.FIVE: return "5"
		CardValue.SIX: return "6"
		CardValue.SEVEN: return "7"
		CardValue.EIGHT: return "8"
		CardValue.NINE: return "9"
		CardValue.SKIP: return "Skip"
		CardValue.REVERSE: return "Reverse"
		CardValue.DRAW_TWO: return "Draw Two"
		CardValue.WILD: return "Wild"
		CardValue.WILD_DRAW_FOUR: return "Wild Draw Four"
		_: return "Unknown"

func card_to_string() -> String:
	if color == CardColor.WILD:
		return value_to_string()
	return "%s of %s" % [value_to_string(), color_to_string()]
	
func is_playable_on(top_card: Card) -> bool:
	# Wild cards can always be played
	if value == CardValue.WILD or value == CardValue.WILD_DRAW_FOUR:
		return true
	# Match color
	if color == top_card.color:
		return true
	# Match value
	if value == top_card.value:
		return true
	# Otherwise, not playable
	return false
