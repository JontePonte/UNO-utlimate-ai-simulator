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
@onready var max_turns_label = $MarginContainer/MainVBox/SmallOptions/MaxRounds/LabelInput/Label
@onready var max_turns_spinbox = $MarginContainer/MainVBox/SmallOptions/MaxRounds/LabelInput/SpinBox

@onready var start_button = $MarginContainer/MainVBox/ButtonHBox/Start
@onready var exit_button = $MarginContainer/MainVBox/ButtonHBox/BackExit/ExitGame
@onready var main_menu_button = $MarginContainer/MainVBox/ButtonHBox/BackExit/Back

var available_ais = []

func _ready():
	# Koppla knappar
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	# 1. SKANNA FILERNA FÖRST (Viktigt!)
	_refresh_ai_lists()
	
	# 2. FYLL ALLA DROPDOWNS DYNAMISKT
	var menus = [bottom_type_opt, left_type_opt, top_type_opt, right_type_opt]
	for menu in menus:
		menu.clear() # Rensa bort "Option 0" etc.
		for i in range(available_ais.size()):
			var ai_info = available_ais[i]
			menu.add_item(ai_info["name"])
			# Här sparar vi filstigen i metadatan så vi slipper ID-nummer!
			menu.set_item_metadata(i, ai_info["path"])
	
	# 3. Koppla signaler för checkboxar
	bottom_human_check.toggled.connect(_on_bottom_human_toggled)
	left_active_check.toggled.connect(_on_left_active_toggled)
	top_active_check.toggled.connect(_on_top_active_toggled)
	right_active_check.toggled.connect(_on_right_active_toggled)
	
	# Koppla signaler för dropdowns
	bottom_type_opt.item_selected.connect(_on_dropdown_changed)
	left_type_opt.item_selected.connect(_on_dropdown_changed)
	top_type_opt.item_selected.connect(_on_dropdown_changed)
	right_type_opt.item_selected.connect(_on_dropdown_changed)
	
	# 4. Koppla och sätt värden för Sliders
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	max_turns_slider.value_changed.connect(_on_max_turns_slider_changed)
	max_turns_spinbox.value_changed.connect(_on_max_turns_spinbox_changed)

	# 5. LADDA INSTÄLLNINGAR (Nu när menyerna faktiskt har innehåll)
	_load_settings_from_autoload()
	
	# 6. Uppdatera UI:t (gråa ut inaktiva slots etc.)
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
	# --- BOTTEN (HUMAN/AI LOGIKEN) ---
	var bottom_idx = bottom_type_opt.selected
	
	if bottom_human_check.button_pressed:
		bottom_type_opt.disabled = true
		bottom_visible_check.button_pressed = true
		bottom_visible_check.disabled = true
		
		# Byt ut texten på det valda alternativet till "You" medan menyn är låst
		if bottom_idx != -1:
			bottom_type_opt.set_item_text(bottom_idx, "You")
	else:
		bottom_type_opt.disabled = false
		bottom_visible_check.disabled = false
		
		# Återställ originalnamnet från vår sparade AI-lista!
		if bottom_idx != -1 and bottom_idx < available_ais.size():
			var original_name = available_ais[bottom_idx]["name"]
			bottom_type_opt.set_item_text(bottom_idx, original_name)
			
	# --- VÄNSTER ---
	if left_active_check.button_pressed:
		left_type_opt.disabled = false
		left_visible_check.disabled = false
	else:
		left_type_opt.disabled = true
		left_visible_check.disabled = true

	# --- TOPP ---
	if top_active_check.button_pressed:
		top_type_opt.disabled = false
		top_visible_check.disabled = false
	else:
		top_type_opt.disabled = true
		top_visible_check.disabled = true

	# --- HÖGER ---
	if right_active_check.button_pressed:
		right_type_opt.disabled = false
		right_visible_check.disabled = false
	else:
		right_type_opt.disabled = true
		right_visible_check.disabled = true

# --- SLIDER FUNKTIONER ---
func _on_speed_slider_changed(value: float):
	speed_label.text = "Game Speed: " + str(value).pad_decimals(1) + "x"

func _on_max_turns_slider_changed(value: float):
	var turns = int(value) 
	max_turns_spinbox.value = turns
func _on_max_turns_spinbox_changed(value: float):
	var turns = int(value) 
	max_turns_slider.value = turns

func _refresh_ai_lists():
	available_ais.clear()
	
	# Hämta fil-listan från vår globala manager
	var ai_files = AiManager.get_all_ai_files()
	
	for file_name in ai_files:
		# Snygga till namnet precis som du gjorde förut
		var display_name = "AI: " + file_name.replace(".json", "").capitalize()
		
		# Lägg till i listan, och använd AiManagers sökväg för att bygga den fullständiga stigen
		available_ais.append({
			"name": display_name,
			"path": AiManager.AI_FOLDER_PATH + file_name
		})

func _load_settings_from_autoload():
	print("Laddar inställningar från GameSettings...")
	
	# --- GLOBALA INSTÄLLNINGAR ---
	speed_slider.value = GameSettings.game_speed
	speed_label.text = "Game Speed: " + str(GameSettings.game_speed).pad_decimals(1) + "x"
	
	max_turns_slider.value = GameSettings.max_turns
	max_turns_spinbox.value = GameSettings.max_turns
	
	# Listor för att kunna loopa (samma ordning som i _save_settings)
	var slot_keys = ["bottom", "left", "top", "right"]
	var active_checks = [null, left_active_check, top_active_check, right_active_check]
	var opts = [bottom_type_opt, left_type_opt, top_type_opt, right_type_opt]
	var vis_checks = [bottom_visible_check, left_visible_check, top_visible_check, right_visible_check]

	for i in range(4):
		var key = slot_keys[i]
		var slot_data = GameSettings.slots[key]
		
		# 1. Ladda aktiv/människa-status
		if i == 0:
			bottom_human_check.button_pressed = slot_data["is_human"]
		else:
			active_checks[i].button_pressed = slot_data["active"]
		
		# 2. Ladda kort-synlighet
		vis_checks[i].button_pressed = slot_data["show_cards"]
		
		# 3. Ladda AI-profilen (Här använder vi den NYA hjälper-funktionen med path!)
		_set_option_by_path(opts[i], slot_data["ai_path"])

func _save_settings_to_autoload():
	print("Sparar inställningar till GameSettings...")
	
	# --- GLOBALA INSTÄLLNINGAR ---
	GameSettings.is_test_mode = false
	GameSettings.game_speed = speed_slider.value
	GameSettings.max_turns = int(max_turns_slider.value)
	
	# Vi skapar listor med våra UI-noder så vi kan loopa igenom dem
	var slot_keys = ["bottom", "left", "top", "right"]
	var active_checks = [null, left_active_check, top_active_check, right_active_check]
	var opts = [bottom_type_opt, left_type_opt, top_type_opt, right_type_opt]
	var vis_checks = [bottom_visible_check, left_visible_check, top_visible_check, right_visible_check]

	for i in range(4):
		var key = slot_keys[i]
		var menu = opts[i]
		
		# 1. Spara om platsen är aktiv (Bottom är alltid sann)
		if i == 0:
			GameSettings.slots[key]["active"] = true
			GameSettings.slots[key]["is_human"] = bottom_human_check.button_pressed
		else:
			GameSettings.slots[key]["active"] = active_checks[i].button_pressed
			GameSettings.slots[key]["is_human"] = false # Bara botten kan vara människa
		
		# 2. Spara om kort ska synas
		GameSettings.slots[key]["show_cards"] = vis_checks[i].button_pressed
		
		# 3. Spara AI-stigen från metadata (Här dör "ai_type" och "ai_path" föds!)
		var selected_idx = menu.selected
		GameSettings.slots[key]["ai_path"] = menu.get_item_metadata(selected_idx)
		
		# 4. Spara namnet (Om människa -> "You", annars dropdownens text)
		if i == 0 and bottom_human_check.button_pressed:
			GameSettings.slots[key]["ai_name"] = "You"
		else:
			GameSettings.slots[key]["ai_name"] = menu.get_item_text(selected_idx)

func _set_option_by_id(opt_btn: OptionButton, id: int):
	# Hittar vilken rad (index) som har det sparade ID:t och väljer den
	var idx = opt_btn.get_item_index(id)
	if idx != -1:
		opt_btn.selected = idx

func _on_start_button_pressed():
	_save_settings_to_autoload()
	
	print("Startar match med nuvarande GameSettings...")
	var err = get_tree().change_scene_to_file("res://game/VisualMatch.scn")
	if err != OK:
		print("Kunde inte ladda VisualMatch! Felkod: ", err)

func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")

func _set_option_by_path(opt_btn: OptionButton, path: String):
	for i in range(opt_btn.item_count):
		if opt_btn.get_item_metadata(i) == path:
			opt_btn.selected = i
			return
	# Om vi inte hittar stigen (t.ex. om en fil tagits bort), välj den första i listan
	opt_btn.selected = 0
