# AIPlayer.gd
class_name AIPlayer

# Standardnamn om man glömmer döpa den i underklassen
var ai_name: String = "Okänd AI"

# Base class / interface for all AI strategies
func choose_action(_view: PlayerView):
	push_error("choose_action() not implemented in AIPlayer")
	return null
