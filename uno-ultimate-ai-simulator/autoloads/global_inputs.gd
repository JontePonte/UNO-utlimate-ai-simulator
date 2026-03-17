extends Node

func _ready():
	toggle_window_mode()

func _input(event):
	# Vi använder _input istället för _unhandled för att "hinna först"
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		toggle_window_mode()
		# Stoppa Godot från att skicka händelsen vidare och trigga felmeddelanden
		get_viewport().set_input_as_handled()

func toggle_window_mode():
	var main_id = DisplayServer.MAIN_WINDOW_ID
	var is_currently_full = DisplayServer.window_get_mode(main_id) != DisplayServer.WINDOW_MODE_WINDOWED
	
	if not is_currently_full:
		# GÅ TILL "FALSK" FULLSCREEN
		# 1. Ta bort fönsterramar
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, main_id)
		# 2. Maximera fönstret så det täcker allt (inklusive Taskbar)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED, main_id)
	else:
		# GÅ TILLBAKA TILL FÖNSTER
		# 1. Sätt tillbaka fönsterramar
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false, main_id)
		# 2. Sätt tillbaka till vanligt fönsterläge
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, main_id)
		
		# 3. TVINGA NER STORLEKEN (viktigt för jobbdatorn!)
		# Vi sätter den till 1600x900 så vi vet att den ryms på 1080p med skalning
		await get_tree().process_frame
		DisplayServer.window_set_size(Vector2i(1600, 900), main_id)
		
		# 4. Centrera
		var screen_rect = DisplayServer.screen_get_usable_rect()
		var center_pos = screen_rect.position + (screen_rect.size / 2) - (Vector2i(1600*0.5, 900*0.5))
		DisplayServer.window_set_position(center_pos, main_id)

	print("Bytte läge! Nytt läge: ", DisplayServer.window_get_mode(main_id))
