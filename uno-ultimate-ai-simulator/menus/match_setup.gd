extends Control

@onready var bottom_type_opt = $MarginContainer/MainVBox/BoardGrid/SlotBottom/OptionButton
@onready var bottom_human_check = $MarginContainer/MainVBox/BoardGrid/SlotBottom/Human
@onready var bottom_visible_check = $MarginContainer/MainVBox/BoardGrid/SlotBottom/VisableCards

@onready var left_type_opt = $MarginContainer/MainVBox/BoardGrid/SlotLeft/OptionButton
@onready var left_active_check = $MarginContainer/MainVBox/BoardGrid/SlotLeft/Active
@onready var left_visible_check = $MarginContainer/MainVBox/BoardGrid/SlotLeft/VisableCards

@onready var start_button = $MarginContainer/MainVBox/ButtonHBox/Start
@onready var exit_button = $MarginContainer/MainVBox/ButtonHBox/ExitGame

func _ready():
	# Koppla knappen till funktionen
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	# 1. Fyll Botten-dropdown (Denna kan vara Human eller AI)
	bottom_type_opt.add_item("Människa", 0)
	bottom_type_opt.add_item("AI: Simple", 1)
	bottom_type_opt.add_item("AI: Aggressive", 2)
	bottom_type_opt.add_item("AI: Custom", 3)
	
	# 2. Fyll AI-dropdowns (Dessa kan bara vara AI)
	left_type_opt.add_item("AI: Simple", 1)
	left_type_opt.add_item("AI: Aggressive", 2)
	left_type_opt.add_item("AI: Custom", 3)
	
	# 3. Koppla signaler för att uppdatera UI:t dynamiskt
	bottom_type_opt.item_selected.connect(_on_bottom_type_changed)
	left_active_check.toggled.connect(_on_left_active_toggled)
	
	# 4. Kör en första uppdatering så allt ser rätt ut från start
	_update_ui_states()

func _on_bottom_type_changed(index: int):
	_update_ui_states()

func _on_left_active_toggled(button_pressed: bool):
	_update_ui_states()

func _update_ui_states():
	# --- BOTTEN (Människa eller AI) ---
	# Om botten är inställd på Människa (index 0), måste korten vara synliga!
	if bottom_type_opt.selected == 0:
		bottom_visible_check.button_pressed = true
		bottom_visible_check.disabled = true # Lås fast den!
	else:
		# Om det är en AI, låt användaren välja om de vill se korten
		bottom_visible_check.disabled = false
		
	# --- VÄNSTER (Aktiv eller Inaktiv) ---
	if left_active_check.button_pressed:
		left_type_opt.disabled = false
		left_visible_check.disabled = false
	else:
		# Om inaktiv, gråa ut dropdown och kortvisning
		left_type_opt.disabled = true
		left_visible_check.disabled = true


func _on_start_button_pressed():
	print("Startar match med nuvarande GameSettings...")
	
	# Byt scen till VisualMatch! 
	# (Från dina bilder ser jag att filen heter VisualMatch.scn och ligger i game-mappen)
	var err = get_tree().change_scene_to_file("res://game/VisualMatch.scn")
	
	if err != OK:
		print("Kunde inte ladda VisualMatch! Felkod: ", err)

func _on_exit_button_pressed():
	get_tree().quit()
