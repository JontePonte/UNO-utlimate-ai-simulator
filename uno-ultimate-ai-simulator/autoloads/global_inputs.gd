extends Node

signal window_mode_changed(is_fullscreen: bool)

var SHOW_REPORT_BUG_BUTTON = true

func _ready():
	# Set windowed att startup
	toggle_window_mode()

func _input(event):
	# Vi använder _input istället för _unhandled för att "hinna först"
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		toggle_window_mode()
		# Stoppa Godot från att skicka händelsen vidare och trigga felmeddelanden
		get_viewport().set_input_as_handled()

func toggle_window_mode():
	var main_id = DisplayServer.MAIN_WINDOW_ID
	
	# --- 1. WEBB-VERSIONEN ---
	if OS.has_feature("web"):
		# På webben fungerar det vanliga FULLSCREEN-läget bäst med webbläsarens inbyggda API
		var is_currently_full = DisplayServer.window_get_mode(main_id) == DisplayServer.WINDOW_MODE_FULLSCREEN
		
		if not is_currently_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, main_id)
			window_mode_changed.emit(true)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, main_id)
			window_mode_changed.emit(false)
			
	# --- 2. PC / MAC / EDITORN (Din beprövade specialkod!) ---
	else:
		var is_currently_full = DisplayServer.window_get_mode(main_id) != DisplayServer.WINDOW_MODE_WINDOWED
		
		if not is_currently_full:
			# GÅ TILL FULLSCREEN (Maximized + Borderless hack)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, main_id)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED, main_id)
			window_mode_changed.emit(true)
		else:
			# GÅ TILL FÖNSTERLÄGE
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false, main_id)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, main_id)
			
			await get_tree().process_frame
			DisplayServer.window_set_size(Vector2i(1600, 900), main_id)
			
			var screen_rect = DisplayServer.screen_get_usable_rect()
			var center_pos = screen_rect.position + (screen_rect.size / 2) - (Vector2i(1600*0.5, 900*0.5))
			DisplayServer.window_set_position(center_pos, main_id)
			
			window_mode_changed.emit(false)
