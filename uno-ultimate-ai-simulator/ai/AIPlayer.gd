# AIPlayer.gd
class_name AIPlayer

# Base class / interface for all AI strategies
func choose_action(_view: PlayerView):
	push_error("choose_action() not implemented in AIPlayer")
	return null
