extends AIPlayer #
class_name AISimple

func choose_action(view: PlayerView) -> PlayerAction:
	for card in view.own_hand:
		if card.is_playable_on(view.top_discard):
			
			# Om det är ett wild-kort, slumpa en färg att skicka med
			if card.color == Card.CardColor.WILD:
				var random_color = _get_random_color()
				return PlayerAction.new(card, random_color)
				
			# Annars, skicka bara kortet (och dess vanliga färg)
			return PlayerAction.new(card, card.color)
			
	# Inget spelbart kort hittades, returnera en action utan kort (betyder "dra kort")
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
