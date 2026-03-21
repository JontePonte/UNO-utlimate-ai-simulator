extends Button

func _ready():
	if OS.has_feature("web"):
		hide()
	# 1. Lyssna på när knappen klickas
	pressed.connect(_on_pressed)
	
	# 2. Lyssna på när F11 trycks via din Autoload (Byt ut 'GlobalInputs' mot vad din Autoload heter i inställningarna!)
	GlobalInputs.window_mode_changed.connect(_update_text)
	
	# 3. Sätt rätt text direkt när knappen laddas in
	var main_id = DisplayServer.MAIN_WINDOW_ID
	var is_full = DisplayServer.window_get_mode(main_id) != DisplayServer.WINDOW_MODE_WINDOWED
	_update_text(is_full)

func _on_pressed():
	# När vi klickar, säg åt Autoloaden att göra sitt jobb!
	GlobalInputs.toggle_window_mode()

func _update_text(is_fullscreen: bool):
	if is_fullscreen:
		text = "Windowed (F11)"
	else:
		text = "Fullscreen (F11)"
