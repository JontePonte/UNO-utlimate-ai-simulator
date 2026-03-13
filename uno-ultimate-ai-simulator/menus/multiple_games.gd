extends Control

@onready var num_players_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxL/NumberOfPlayers/OptionButton
@onready var slot3 = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot3
@onready var slot4 = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot4

@onready var match_count_spinbox = $MarginContainer/MainVBox/HBoxCenter/VBoxL/NumberOfMatches/SpinBox
@onready var slot1_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot1/OptionButton
@onready var slot2_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot2/OptionButton
@onready var slot3_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot3/OptionButton
@onready var slot4_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot4/OptionButton

@onready var max_turns_spinbox = $MarginContainer/MainVBox/HBoxCenter/VBoxL/MaxRounds2/SpinBox

@onready var progress_bar = $MarginContainer/MainVBox/BottomHBox/HBoxSim/ProgressBar
@onready var results_label = $MarginContainer/MainVBox/BottomHBox/ResultsLabel

@onready var start_button = $MarginContainer/MainVBox/BottomHBox/HBoxSim/Start
@onready var exit_button = $MarginContainer/MainVBox/BottomHBox/HBoxSim/HBoxBackExit/ExitGame
@onready var main_menu_button = $MarginContainer/MainVBox/BottomHBox/HBoxSim/HBoxBackExit/Back


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Koppla knappar
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	num_players_opt.add_item("2", 2) # Texten är "2", ID:t är 2
	num_players_opt.add_item("3", 3)
	num_players_opt.add_item("4", 4)
	
	# Sätt 4 spelare som standard (index 2 är den tredje saken i listan)
	num_players_opt.selected = 2 
	
	# Lyssna på ändringar
	num_players_opt.item_selected.connect(_on_num_players_changed)
	
	# Kör en första uppdatering så rätt slots syns
	_update_player_slots()

func _on_num_players_changed(_index: int):
	_update_player_slots()

func _update_player_slots():
	# Hämta ID:t från det valda alternativet (som vi satte till 2, 3 eller 4)
	var num_players = num_players_opt.get_item_id(num_players_opt.selected)
	
	if num_players == 2:
		slot3.hide()
		slot4.hide()
	elif num_players == 3:
		slot3.show()
		slot4.hide()
	elif num_players == 4:
		slot3.show()
		slot4.show()

func _create_players_for_sim(num_players: int) -> Array[Player]:
	var players: Array[Player] = []
	var slots = [slot1_opt, slot2_opt, slot3_opt, slot4_opt]
	
	for i in range(num_players):
		# 1. Hämta valet från dropdownen
		var ai_id = slots[i].get_item_id(slots[i].selected)
		
		# Vi skapar ALLTID en AIInterpreter nu
		var ai_strategy = AIInterpreter.new()
		
		# 2. Ladda rätt "hjärna" baserat på ID
		# (Vi antar att ID 1 = Test/Simple och ID 2 = Aggressive)
		match ai_id:
			1: 
				ai_strategy.load_profile("res://ai_profiles/test_ai.json")
			2: 
				ai_strategy.load_profile("res://ai_profiles/aggressive_ai.json")
			_: 
				ai_strategy.load_profile("res://ai_profiles/test_ai.json")
			
		# 3. Skapa spelaren med den tolken
		var player_name = "Player " + str(i + 1)
		# Vi skickar med ai_strategy (som nu är en AIInterpreter med laddad JSON)
		var player = Player.new(i, player_name, false, ai_strategy)
		
		players.append(player)
		
	return players

func _on_start_button_pressed():
	print("--- STARTAR SIMULERING ---")
	
	var num_matches = int(match_count_spinbox.value)
	var num_players = num_players_opt.get_item_id(num_players_opt.selected)
	
	# NYTT: Hämta värdet från max_turns_spinbox
	var max_turns = int(max_turns_spinbox.value) 
	
	# Gör i ordning UI:t för laddningen
	progress_bar.max_value = num_matches
	progress_bar.value = 0
	progress_bar.show()
	results_label.text = "Simulating " + str(num_matches) + " matches...\nPlease Wait!"
	
	# Dictionary för att hålla koll på resultatet
	var scoreboard = {
		"Draw": 0
	}
	for i in range(num_players):
		scoreboard["Player " + str(i + 1)] = 0
		
	var start_time = Time.get_ticks_msec() # För att mäta hur snabbt det går!
	
	# --- HUVUDLOOP ---
	for i in range(num_matches):
		var players = _create_players_for_sim(num_players)
		var sim_manager = SimulationManager.new(players)
		
		var result = await sim_manager.run_match(max_turns) 
		
		if i == 0:
			sim_manager.save_debug_log("res://debug_match_log.txt")
		
		# Registrera vinsten
		var winner = result["winner_name"]
		if scoreboard.has(winner):
			scoreboard[winner] += 1
		else:
			scoreboard[winner] = 1
			
		# --- UI UPPDATERING OCH BATCHING ---
		progress_bar.value = i + 1
		
		if i % 50 == 0:
			await get_tree().process_frame
			
	# --- SIMULERING KLAR ---
	var end_time = Time.get_ticks_msec()
	var time_taken = (end_time - start_time) / 1000.0
	
	# --- BYGG RESULTAT-TEXTEN ---
	var final_text = "--- SIMULATION COMPLETE ---\n" # Ändrade till engelska för att matcha ditt UI
	final_text += "Total number of Matches: " + str(num_matches) + "\n"
	final_text += "Time: " + str(time_taken).pad_decimals(2) + " seconds\n\n"
	
	# Räkna ut vinstprocent och lägg till i texten
	for player_name in scoreboard.keys():
		var wins = scoreboard[player_name]
		var win_rate = (float(wins) / float(num_matches)) * 100.0
		
		# Snyggare utskrift ifall det är "Draw"
		if player_name == "Draw":
			final_text += "Draws (Reached Max Turns): " + str(wins) + " (" + str(win_rate).pad_decimals(1) + "%)\n"
		else:
			final_text += player_name + ": " + str(wins) + " wins (" + str(win_rate).pad_decimals(1) + "%)\n"
		
	# Visa det snygga resultatet på skärmen!
	results_label.text = final_text

func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
