# AISimple.gd
extends AIPlayer
class_name AISimple

# Very simple AI: plays the first playable card it finds
func choose_action(view: PlayerView) -> Card:
	for card in view.hand:
		if card.is_playable_on(view.top_discard):
			return card
	return null  # nothing playable
