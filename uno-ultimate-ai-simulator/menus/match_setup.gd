extends Control

@onready var bottom_type_opt = $MarginContainer/MainVBox/BoardGrid/SlotBottom/OptionButton
@onready var bottom_human_check = $MarginContainer/MainVBox/BoardGrid/SlotBottom/Human
@onready var bottom_visible_check = $MarginContainer/MainVBox/BoardGrid/SlotBottom/VisableCards
@onready var bottom_name_label = $MarginContainer/MainVBox/BoardGrid/SlotBottom/NameLabel


@onready var left_type_opt = $MarginContainer/MainVBox/BoardGrid/SlotLeft/OptionButton
@onready var left_active_check = $MarginContainer/MainVBox/BoardGrid/SlotLeft/Active
@onready var left_visible_check = $MarginContainer/MainVBox/BoardGrid/SlotLeft/VisableCards
@onready var left_name_label = $MarginContainer/MainVBox/BoardGrid/SlotLeft/NameLabel

@onready var right_type_opt = $MarginContainer/MainVBox/BoardGrid/SlotRight/OptionButton
@onready var right_active_check = $MarginContainer/MainVBox/BoardGrid/SlotRight/Active
@onready var right_visible_check = $MarginContainer/MainVBox/BoardGrid/SlotRight/VisableCards
@onready var right_name_label = $MarginContainer/MainVBox/BoardGrid/SlotRight/NameLabel

@onready var top_type_opt = $MarginContainer/MainVBox/BoardGrid/SlotTop/OptionButton
@onready var top_active_check = $MarginContainer/MainVBox/BoardGrid/SlotTop/Active
@onready var top_visible_check = $MarginContainer/MainVBox/BoardGrid/SlotTop/VisableCards
@onready var top_name_label = $MarginContainer/MainVBox/BoardGrid/SlotTop/NameLabel

@onready var speed_slider = $MarginContainer/MainVBox/SmallOptions/SpeedSlider/HSlider
@onready var speed_label = $MarginContainer/MainVBox/SmallOptions/SpeedSlider/Label

@onready var max_turns_slider = $MarginContainer/MainVBox/SmallOptions/MaxRounds/HSlider
@onready var max_turns_label = $MarginContainer/MainVBox/SmallOptions/MaxRounds/Label2

@onready var start_button = $MarginContainer/MainVBox/ButtonHBox/Start
@onready var exit_button = $MarginContainer/MainVBox/ButtonHBox/ExitGame

func _ready():
	# Koppla knappar
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	
	# 1. Fyll Botten-dropdown (Siffran på slutet är ID, som matchar AIType)
	bottom_type_opt.add_item("AI: Simple", 1)
	bottom_type_opt.add_item("AI: Aggressive", 2)
	bottom_type_opt.add_item("AI: Custom", 3)
	
	# 2. Fyll AI-dropdowns för övriga stolar
	left_type_opt.add_item("AI: Simple", 1)
	left_type_opt.add_item("AI: Aggressive", 2)
	left_type_opt.add_item("AI: Custom", 3)
	
	top_type_opt.add_item("AI: Simple", 1)
	top_type_opt.add_item("AI: Aggressive", 2)
	top_type_opt.add_item("AI: Custom", 3)
	
	right_type_opt.add_item("AI: Simple", 1)
	right_type_opt.add_item("AI: Aggressive", 2)
	right_type_opt.add_item("AI: Custom", 3)
	
	# 3. Koppla signaler för att uppdatera UI:t dynamiskt
	bottom_human_check.toggled.connect(_on_bottom_human_toggled)
	left_active_check.toggled.connect(_on_left_active_toggled)
	top_active_check.toggled.connect(_on_top_active_toggled)
	right_active_check.toggled.connect(_on_right_active_toggled)
	
	# Lyssna på när användaren byter AI-typ
	bottom_type_opt.item_selected.connect(_on_dropdown_changed)
	left_type_opt.item_selected.connect(_on_dropdown_changed)
	top_type_opt.item_selected.connect(_on_dropdown_changed)
	right_type_opt.item_selected.connect(_on_dropdown_changed)
	
	# Sliders
	speed_slider.value = GameSettings.game_speed
	speed_label.text = "Game Speed: " + str(GameSettings.game_speed).pad_decimals(1) + "x"
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	
	max_turns_slider.value = GameSettings.max_turns
	max_turns_label.text = "Max Rounds: " + str(GameSettings.max_turns)
	max_turns_slider.value_changed.connect(_on_max_turns_slider_changed)
	
	# Koppla slider-signaler (men sätt inte värdet här längre)
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	max_turns_slider.value_changed.connect(_on_max_turns_slider_changed)
	
	# 4. Ladda in allt från GameSettings!
	_load_settings_from_autoload()
	
	# 5. Kör en första uppdatering så rätt saker gråas ut baserat på det vi just laddade in
	_update_ui_states()

# --- SIGNAL MOTTAGARE FÖR CHECKBOXAR ---
func _on_bottom_human_toggled(_button_pressed: bool):
	_update_ui_states()

func _on_left_active_toggled(_button_pressed: bool):
	_update_ui_states()

func _on_top_active_toggled(_button_pressed: bool):
	_update_ui_states()

func _on_right_active_toggled(_button_pressed: bool):
	_update_ui_states()
	
func _on_dropdown_changed(_index: int):
	# Kör samma ui-uppdatering som checkboxarna gör!
	_update_ui_states()

func _update_ui_states():
	# --- BOTTEN ---
	if bottom_human_check.button_pressed:
		bottom_type_opt.disabled = true
		bottom_visible_check.button_pressed = true
		bottom_visible_check.disabled = true
		bottom_name_label.text = "Bottom: You"
	else:
		bottom_type_opt.disabled = false
		bottom_visible_check.disabled = false
		# Hämta texten från det valda alternativet i dropdownen
		var selected_text = bottom_type_opt.get_item_text(bottom_type_opt.selected)
		bottom_name_label.text = "Bottom: " + selected_text
		
	# --- VÄNSTER ---
	if left_active_check.button_pressed:
		left_type_opt.disabled = false
		left_visible_check.disabled = false
		var selected_text = left_type_opt.get_item_text(left_type_opt.selected)
		left_name_label.text = "Left: " + selected_text
	else:
		left_type_opt.disabled = true
		left_visible_check.disabled = true
		left_name_label.text = "Left: Empty"

	# --- TOPP ---
	if top_active_check.button_pressed:
		top_type_opt.disabled = false
		top_visible_check.disabled = false
		var selected_text = top_type_opt.get_item_text(top_type_opt.selected)
		top_name_label.text = "Top: " + selected_text
	else:
		top_type_opt.disabled = true
		top_visible_check.disabled = true
		top_name_label.text = "Top: Empty"

	# --- HÖGER ---
	if right_active_check.button_pressed:
		right_type_opt.disabled = false
		right_visible_check.disabled = false
		var selected_text = right_type_opt.get_item_text(right_type_opt.selected)
		right_name_label.text = "Right: " + selected_text
	else:
		right_type_opt.disabled = true
		right_visible_check.disabled = true
		right_name_label.text = "Right: Empty"

# --- SLIDER FUNKTIONER ---
func _on_speed_slider_changed(value: float):
	speed_label.text = "Game Speed: " + str(value).pad_decimals(1) + "x"

func _on_max_turns_slider_changed(value: float):
	var turns = int(value) 
	max_turns_label.text = "Max Rounds: " + str(turns)

func _load_settings_from_autoload():
	print("Laddar inställningar från GameSettings...")
	
	# --- GLOBALA INSTÄLLNINGAR ---
	speed_slider.value = GameSettings.game_speed
	speed_label.text = "Game Speed: " + str(GameSettings.game_speed).pad_decimals(1) + "x"
	
	max_turns_slider.value = GameSettings.max_turns
	max_turns_label.text = "Max Rounds: " + str(GameSettings.max_turns)
	
	# --- BOTTEN ---
	bottom_human_check.button_pressed = GameSettings.slots["bottom"]["is_human"]
	bottom_visible_check.button_pressed = GameSettings.slots["bottom"]["show_cards"]
	_set_option_by_id(bottom_type_opt, GameSettings.slots["bottom"]["ai_type"])
	
	# --- VÄNSTER ---
	left_active_check.button_pressed = GameSettings.slots["left"]["active"]
	left_visible_check.button_pressed = GameSettings.slots["left"]["show_cards"]
	_set_option_by_id(left_type_opt, GameSettings.slots["left"]["ai_type"])

	# --- TOPP ---
	top_active_check.button_pressed = GameSettings.slots["top"]["active"]
	top_visible_check.button_pressed = GameSettings.slots["top"]["show_cards"]
	_set_option_by_id(top_type_opt, GameSettings.slots["top"]["ai_type"])

	# --- HÖGER ---
	right_active_check.button_pressed = GameSettings.slots["right"]["active"]
	right_visible_check.button_pressed = GameSettings.slots["right"]["show_cards"]
	_set_option_by_id(right_type_opt, GameSettings.slots["right"]["ai_type"])

func _save_settings_to_autoload():
	print("Sparar inställningar till GameSettings...")
	
	# --- GLOBALA INSTÄLLNINGAR ---
	GameSettings.game_speed = speed_slider.value
	GameSettings.max_turns = int(max_turns_slider.value)
	
	# --- BOTTEN ---
	GameSettings.slots["bottom"]["active"] = true 
	GameSettings.slots["bottom"]["is_human"] = bottom_human_check.button_pressed
	GameSettings.slots["bottom"]["show_cards"] = bottom_visible_check.button_pressed
	GameSettings.slots["bottom"]["ai_type"] = bottom_type_opt.get_item_id(bottom_type_opt.selected)
	
	# NYTT: Sätt namnet baserat på om det är en människa eller AI
	if bottom_human_check.button_pressed:
		GameSettings.slots["bottom"]["ai_name"] = "You"
	else:
		GameSettings.slots["bottom"]["ai_name"] = bottom_type_opt.get_item_text(bottom_type_opt.selected)
	
	# --- VÄNSTER ---
	GameSettings.slots["left"]["active"] = left_active_check.button_pressed
	GameSettings.slots["left"]["is_human"] = false
	GameSettings.slots["left"]["show_cards"] = left_visible_check.button_pressed
	GameSettings.slots["left"]["ai_type"] = left_type_opt.get_item_id(left_type_opt.selected)
	# NYTT: Hämta namnet direkt från dropdown-menyn
	GameSettings.slots["left"]["ai_name"] = left_type_opt.get_item_text(left_type_opt.selected)

	# --- TOPP ---
	GameSettings.slots["top"]["active"] = top_active_check.button_pressed
	GameSettings.slots["top"]["is_human"] = false
	GameSettings.slots["top"]["show_cards"] = top_visible_check.button_pressed
	GameSettings.slots["top"]["ai_type"] = top_type_opt.get_item_id(top_type_opt.selected)
	# NYTT
	GameSettings.slots["top"]["ai_name"] = top_type_opt.get_item_text(top_type_opt.selected)

	# --- HÖGER ---
	GameSettings.slots["right"]["active"] = right_active_check.button_pressed
	GameSettings.slots["right"]["is_human"] = false
	GameSettings.slots["right"]["show_cards"] = right_visible_check.button_pressed
	GameSettings.slots["right"]["ai_type"] = right_type_opt.get_item_id(right_type_opt.selected)
	# NYTT
	GameSettings.slots["right"]["ai_name"] = right_type_opt.get_item_text(right_type_opt.selected)

func _set_option_by_id(opt_btn: OptionButton, id: int):
	# Hittar vilken rad (index) som har det sparade ID:t och väljer den
	var idx = opt_btn.get_item_index(id)
	if idx != -1:
		opt_btn.selected = idx

# --- START & EXIT ---
func _on_start_button_pressed():
	_save_settings_to_autoload()
	
	print("Startar match med nuvarande GameSettings...")
	var err = get_tree().change_scene_to_file("res://game/VisualMatch.scn")
	if err != OK:
		print("Kunde inte ladda VisualMatch! Felkod: ", err)

func _on_exit_button_pressed():
	get_tree().quit()
