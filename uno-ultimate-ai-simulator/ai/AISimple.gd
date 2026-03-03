extends AIPlayer #
class_name AISimple

func choose_action(view: PlayerView) -> PlayerAction:
	for card in view.own_hand:
		# Här skickar vi nu med view.current_color!
		if card.is_playable_on(view.top_discard, view.current_color):
			
			if card.color == Card.CardColor.WILD:
				var random_color = _get_random_color()
				return PlayerAction.new(card, random_color)
				
			return PlayerAction.new(card, card.color)
			
	return PlayerAction.new(null)

# Privat hjälpfunktion för att slumpa färg
func _get_random_color() -> Card.CardColor:
	var colors = [
		Card.CardColor.RED, 
		Card.CardColor.YELLOW, 
		Card.CardColor.BLUE, 
		Card.CardColor.GREEN
	]
	return colors[randi() % colors.size()]
