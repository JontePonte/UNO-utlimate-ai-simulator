extends ColorRect # (Om du använde en Panel, låt det stå "extends Panel" här istället)

func _unhandled_input(event):
	# Vi lyssnar efter knapptryck
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			
			# Eftersom PauseOverlay är ett barn till VisualMatch, 
			# kan vi be dess "förälder" att köra funktionen!
			get_parent()._toggle_pause()
