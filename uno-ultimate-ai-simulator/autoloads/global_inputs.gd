extends Node

# _unhandled_key_input är mycket säkrare än _input för globala kortkommandon!
# Den triggas bara av tangentbordet, och ignoreras helt av mus/UI-menyer.
func _unhandled_key_input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		
		# get_tree().root är det ABSOLUTA botten-fönstret (spelet självt)
		var root_window = get_tree().root
		
		if root_window.mode == Window.MODE_FULLSCREEN or root_window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			root_window.mode = Window.MODE_WINDOWED
		else:
			root_window.mode = Window.MODE_FULLSCREEN
			
		# Säg åt spelet att vi hanterat knapptrycket
		get_viewport().set_input_as_handled()
