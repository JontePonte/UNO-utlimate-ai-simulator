class_name CardUI
extends Control

@onready var background = $ColorRect
@onready var label = $ColorRect/Label

# Denna funktion anropas när vi vill visa ett specifikt kort på skärmen
func set_card_data(card: Card):
	if card == null:
		return
		
	# 1. Sätt rätt text baserat på valören
	label.text = get_value_string(card.value)
	
	# 2. Sätt rätt färg baserat på kortets färg
	match card.color:
		Card.CardColor.RED:
			background.color = Color(0.8, 0.1, 0.1) # Röd
		Card.CardColor.BLUE:
			background.color = Color(0.1, 0.3, 0.8) # Blå
		Card.CardColor.GREEN:
			background.color = Color(0.1, 0.6, 0.2) # Grön
		Card.CardColor.YELLOW:
			background.color = Color(0.9, 0.8, 0.1) # Gul
		Card.CardColor.WILD:
			background.color = Color(0.2, 0.2, 0.2) # Mörkgrå för Wild

# Hjälpfunktion för att göra valören till text
func get_value_string(val: Card.CardValue) -> String:
	match val:
		Card.CardValue.ZERO: return "0"
		Card.CardValue.ONE: return "1"
		# ... fortsätt för 2-9 ...
		Card.CardValue.SKIP: return "SKIP"
		Card.CardValue.REVERSE: return "REV"
		Card.CardValue.DRAW_TWO: return "+2"
		Card.CardValue.WILD: return "WILD"
		Card.CardValue.WILD_DRAW_FOUR: return "+4"
		_: return "?"
