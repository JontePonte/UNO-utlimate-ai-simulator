extends Control

@onready var match_mode_dropdown = $MarginContainer/MainVBox/MatchModeDropdown
@onready var repeated_matchup_container = $MarginContainer/MainVBox/RepeatedMatchup
@onready var round_robin_container = $MarginContainer/MainVBox/RoundRobin

# Repeated Matchup
@onready var num_players_opt = $MarginContainer/MainVBox/RepeatedMatchup/VBoxL/NumberOfPlayers/OptionButton
@onready var slot3 = $MarginContainer/MainVBox/RepeatedMatchup/VBoxR/Slot3
@onready var slot4 = $MarginContainer/MainVBox/RepeatedMatchup/VBoxR/Slot4

@onready var match_count_spinbox = $MarginContainer/MainVBox/RepeatedMatchup/VBoxL/NumberOfMatches/SpinBox
@onready var slot1_opt = $MarginContainer/MainVBox/RepeatedMatchup/VBoxR/Slot1/OptionButton
@onready var slot2_opt = $MarginContainer/MainVBox/RepeatedMatchup/VBoxR/Slot2/OptionButton
@onready var slot3_opt = $MarginContainer/MainVBox/RepeatedMatchup/VBoxR/Slot3/OptionButton
@onready var slot4_opt = $MarginContainer/MainVBox/RepeatedMatchup/VBoxR/Slot4/OptionButton

@onready var repeated_max_turns_spinbox = $MarginContainer/MainVBox/RepeatedMatchup/VBoxL/MaxRounds2/SpinBox
@onready var randomize_seats_checkbox = $MarginContainer/MainVBox/RepeatedMatchup/VBoxL/RandomizeSeats/CheckBox

# Round Robin
@onready var two_player_checkbox = $MarginContainer/MainVBox/RoundRobin/VBoxL/TwoPlayerCheckBox
@onready var three_player_checkbox = $MarginContainer/MainVBox/RoundRobin/VBoxL/ThreePlayerCheckBox
@onready var four_player_checkbox = $MarginContainer/MainVBox/RoundRobin/VBoxL/FourPlayerCheckBox
@onready var no_selected_label = $MarginContainer/MainVBox/RoundRobin/VBoxL/NoSelectedLabel # Använd inte hide här utan mellanslag för att skriva tomt
@onready var matchup_number_spin_box = $MarginContainer/MainVBox/RoundRobin/VBoxL/MatchupNumber/SpinBox
@onready var total_match_number_label = $MarginContainer/MainVBox/RoundRobin/VBoxL/TotalMatchNumber

@onready var available_ai_list = $MarginContainer/MainVBox/RoundRobin/AvailableAIList/ItemList
@onready var selected_ai_list = $MarginContainer/MainVBox/RoundRobin/SelectedAIList/ItemList

@onready var add_one_btn = $MarginContainer/MainVBox/RoundRobin/ListControButtons/AddOne
@onready var add_five_btn = $MarginContainer/MainVBox/RoundRobin/ListControButtons/AddFive
@onready var remove_all_selected_btn = $MarginContainer/MainVBox/RoundRobin/ListControButtons/RemoveAllSelected
@onready var clear_selected_list_btn = $MarginContainer/MainVBox/RoundRobin/ListControButtons/ClearSelectedList

@onready var round_robin_max_turns_spinbox = $MarginContainer/MainVBox/RoundRobin/VBoxL/MaxRounds2/SpinBox

# Bottom
@onready var progress_bar = $MarginContainer/MainVBox/BottomHBox/HBoxSim/ProgressBar
@onready var results_label = $MarginContainer/MainVBox/BottomHBox/VBoxRusults/Results

@onready var start_button = $MarginContainer/MainVBox/BottomHBox/HBoxSim/Start
@onready var exit_button = $MarginContainer/MainVBox/BottomHBox/HBoxSim/HBoxBackExit/ExitGame
@onready var main_menu_button = $MarginContainer/MainVBox/BottomHBox/HBoxSim/HBoxBackExit/Back

# En lista som sparar information om de AI:s vi hittar { "name": "Test AI", "path": "res://..." }
var available_ais = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("web"):
		exit_button.hide()
	
	# Koppla signalen till bytar-funktionen
	match_mode_dropdown.item_selected.connect(_on_match_mode_changed)

	# Kör bytet en gång manuellt direkt vid start, så att rätt meny syns från sekund 1
	_on_match_mode_changed(match_mode_dropdown.selected)
	
	#-------------------- Repeaded Matchup --------------------------
	# Koppla knappar
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	num_players_opt.add_item("2", 2) # Texten är "2", ID:t är 2
	num_players_opt.add_item("3", 3)
	num_players_opt.add_item("4", 4)
	
	# Sätt 4 spelare som standard (index 2 är den tredje saken i listan)
	num_players_opt.selected = 2 
	num_players_opt.item_selected.connect(_on_num_players_changed)
	
	# Kör en första uppdatering så rätt slots syns
	_update_player_slots()
	
	#----------------------- Round Robin --------------------------
	# Koppla listornas "någon klickade på en rad"-signal
	available_ai_list.item_selected.connect(_on_available_list_selected)
	selected_ai_list.item_selected.connect(_on_selected_list_selected)
	
	# Koppla listornas "dubbelklick"-signal (aktiverad)
	available_ai_list.item_activated.connect(_on_available_list_activated)
	selected_ai_list.item_activated.connect(_on_selected_list_activated)
	
	# Koppla knapparna i mitten
	add_one_btn.pressed.connect(_on_add_one_pressed)
	add_five_btn.pressed.connect(_on_add_five_pressed)
	remove_all_selected_btn.pressed.connect(_on_remove_all_selected_pressed)
	clear_selected_list_btn.pressed.connect(_on_clear_selected_list_pressed)
	
	# Koppla signaler för Round Robin-kalkylatorn (Vi skickar dem direkt till _update_math)
	two_player_checkbox.pressed.connect(_update_math)
	three_player_checkbox.pressed.connect(_update_math)
	four_player_checkbox.pressed.connect(_update_math)
	matchup_number_spin_box.value_changed.connect(func(_val): _update_math()) # value_changed skickar med ett värde vi måste fånga upp
	match_mode_dropdown.item_selected.connect(func(_val): _update_math()) # Kör matten när vi byter flik så knappen låser/låser upp sig rätt
	_update_math()
	
	_refresh_ai_lists()
	_load_sim_settings()

func _refresh_ai_lists():
	available_ais.clear()
	
	# 1. Hämta fil-listan från vår globala manager
	var ai_files = AiManager.get_all_ai_files()
	
	# 2. Loopa igenom filerna och cacha dem för snabb simulering
	for file_name in ai_files:
		var path = AiManager.AI_FOLDER_PATH + file_name
		
		# Läs filen direkt från användarens mapp
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var json_data = JSON.parse_string(json_text)
			file.close() # Bra vana att stänga filen när vi är klara
			
			if json_data:
				var display_name = "AI: " + file_name.replace(".json", "").capitalize()
				available_ais.append({
					"name": display_name,
					"brain_data": json_data # Vi sparar hela datan här för snabbhet!
				})
	
	# 3. Uppdatera menyerna
	var menus = [slot1_opt, slot2_opt, slot3_opt, slot4_opt]
	for menu in menus:
		menu.clear()
		for i in range(available_ais.size()):
			menu.add_item(available_ais[i]["name"])
			# Vi sparar INDEX till till vår lista istället för en filstig
			menu.set_item_metadata(i, i)
	
	# Töm vänstra listan innan vi fyller på
	available_ai_list.clear()
	
	for i in range(available_ais.size()):
		available_ai_list.add_item(available_ais[i]["name"])
		# Spara index som "metadata" så vi vet vilken AI detta är
		available_ai_list.set_item_metadata(i, i)

func _on_match_mode_changed(index: int):
	if index == 0:
		# --- REPEATED MATCHUP ---
		repeated_matchup_container.show()
		round_robin_container.hide()
		
		# I Repeated Matchup är det alltid okej att starta (om vi inte bygger in fler spärrar senare)
		start_button.disabled = false 
		
	elif index == 1:
		# --- ROUND ROBIN ---
		repeated_matchup_container.hide()
		round_robin_container.show()
		
	# Kör kalkylatorn varje gång vi byter vy! 
	# Om vi precis bytte till Round Robin, kommer kalkylatorn kolla om 
	# vi har giltiga inställningar, annars stänger den av Start-knappen.
	_update_math()

func _create_players_for_sim(num_players: int) -> Array[Player]:
	var players: Array[Player] = []
	var slots = [slot1_opt, slot2_opt, slot3_opt, slot4_opt]
	
	for i in range(num_players):
		var menu = slots[i]
		var ai_index = menu.get_item_metadata(menu.selected)
		
		# Hämta den för-laddade datan från vår lista
		var cached_ai_data = available_ais[ai_index]["brain_data"]
		
		var ai_strategy = AIInterpreter.new()
		# Använd den snabba funktionen som inte rör hårddisken!
		ai_strategy.load_from_data(cached_ai_data)
			
		var player_name = "Player " + str(i + 1)
		var player = Player.new(i, player_name, false, ai_strategy)
		players.append(player)
		
	return players

func _on_num_players_changed(_index: int):
	_update_player_slots()

func _update_player_slots():
	var num_players = num_players_opt.get_item_id(num_players_opt.selected)
	slot3.visible = num_players >= 3
	slot4.visible = num_players >= 4

func _on_start_button_pressed():
	print("--- STARTAR SIMULERING ---")
	_save_sim_settings()
	
	# Nollställ UI
	progress_bar.value = 0
	progress_bar.show()
	results_label.text = "Simulating matches...\nPlease Wait!"
	
	# Välj rätt motor!
	if match_mode_dropdown.selected == 0:
		await _run_repeated_matchup()
	else:
		await _run_round_robin()

func _run_repeated_matchup():	
	var num_matches = int(match_count_spinbox.value)
	var num_players = num_players_opt.get_item_id(num_players_opt.selected)
	
	# NYTT: Hämta värdet från repeated_max_turns_spinbox
	var max_turns = int(repeated_max_turns_spinbox.value) 
	
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
		# 1. Skapa spelarna
		var players = _create_players_for_sim(num_players)
		
		# 2. Blanda stolarna om rutan är ikryssad
		if randomize_seats_checkbox.button_pressed:
			players.shuffle()
		
		# 3. Kör matchen
		var sim_manager = SimulationManager.new(players)
		var result = await sim_manager.run_match(max_turns)
		
		if i == 0:
			sim_manager.save_debug_log("user://debug_match_log.txt")
		
		# 4. Registrera vinsten
		# Eftersom vi eventuellt har blandat spelarna, måste vi ge poängen till 
		# det ORIGINAL-namn (Player 1, Player 2) de fick när vi skapade dem.
		var winner_name = result["winner_name"]
		
		if winner_name == "Draw":
			scoreboard["Draw"] += 1
		else:
			# winner_name kommer vara t.ex. "Player 1", oavsett vilken stol de fick i just denna match
			if scoreboard.has(winner_name):
				scoreboard[winner_name] += 1
			
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

# --- ROUND ROBIN TOURNAMENT ENGINE ---

# --- ROUND ROBIN TOURNAMENT ENGINE ---

func _run_round_robin():
	var n = selected_ai_list.item_count
	
	# 1. SAMLA IN LAGUPPSTÄLLNINGEN (Roster)
	var roster_names = []
	var roster_stats = {} 
	
	for i in range(n):
		var ai_index = selected_ai_list.get_item_metadata(i)
		var base_name = available_ais[ai_index]["name"]
		
		# Skapa ett unikt namn ("#1 AI: Standard") för att hantera dubbletter
		var unique_name = "#" + str(i + 1) + " " + base_name
		roster_names.append(unique_name)
		
		# NU TRACKAR VI ÄVEN SPECIFIKA MATCHTYPER!
		roster_stats[unique_name] = {
			"ai_index": ai_index,
			"wins_total": 0, "matches_total": 0,
			"wins_2": 0, "matches_2": 0,
			"wins_3": 0, "matches_3": 0,
			"wins_4": 0, "matches_4": 0
		}
		
# 2. GENERERA MATCH-SCHEMAT (Nu med dynamisk balansering!)
	var match_queue = []
	var active_types = []
	
	# Vi sparar köerna temporärt för att kunna jämföra dem innan vi slår ihop dem
	var temp_queues = []
	var max_matches_per_ai = 0
	
	if two_player_checkbox.button_pressed and n >= 2:
		var q2 = _generate_matchups(roster_names, 2)
		# Räkna ut hur många matcher EN specifik AI spelar i denna kö: (Totalt antal matcher * 2 spelare) / Antal AI
		var ai_matches = (q2.size() * 2) / n
		temp_queues.append({"type": 2, "queue": q2, "ai_matches": ai_matches})
		max_matches_per_ai = max(max_matches_per_ai, ai_matches)
		active_types.append(2)
		
	if three_player_checkbox.button_pressed and n >= 3:
		var q3 = _generate_matchups(roster_names, 3)
		var ai_matches = (q3.size() * 3) / n
		temp_queues.append({"type": 3, "queue": q3, "ai_matches": ai_matches})
		max_matches_per_ai = max(max_matches_per_ai, ai_matches)
		active_types.append(3)
		
	if four_player_checkbox.button_pressed and n >= 4:
		var q4 = _generate_matchups(roster_names, 4)
		var ai_matches = (q4.size() * 4) / n
		temp_queues.append({"type": 4, "queue": q4, "ai_matches": ai_matches})
		max_matches_per_ai = max(max_matches_per_ai, ai_matches)
		active_types.append(4)
		
	# Nu applicerar vi multiplikatorn och bygger den slutgiltiga match_queue
	for q_data in temp_queues:
		var multiplier = 1
		if q_data["ai_matches"] > 0:
			# Räkna ut hur många gånger denna kö måste repeteras för att komma ikapp max-kön
			multiplier = round(float(max_matches_per_ai) / float(q_data["ai_matches"]))
			multiplier = max(1, multiplier) # Säkerhetsspärr så den alltid körs minst 1 gång
			
		for i in range(multiplier):
			match_queue.append_array(q_data["queue"])
			
	# Lägg på användarens egna "Tournament Repetitions" ovanpå allt
	var repetitions = int(matchup_number_spin_box.value)
	var full_queue = []
	for i in range(repetitions):
		full_queue.append_array(match_queue)
		
	var total_matches = full_queue.size()
	progress_bar.max_value = total_matches
	
	var draws = 0
	var max_turns = int(round_robin_max_turns_spinbox.value)
	var start_time = Time.get_ticks_msec()
	
	# 3. SPELA ALLA MATCHER
	for i in range(total_matches):
		var current_match_names = full_queue[i].duplicate() 
		current_match_names.shuffle() 
		
		# Hämta matchtypen direkt från listans storlek! (Kommer vara 2, 3 eller 4)
		var match_type = current_match_names.size() 
		var players: Array[Player] = []
		
		for p_idx in range(current_match_names.size()):
			var p_name = current_match_names[p_idx]
			var ai_index = roster_stats[p_name]["ai_index"]
			
			var cached_ai_data = available_ais[ai_index]["brain_data"]
			var ai_strategy = AIInterpreter.new()
			ai_strategy.load_from_data(cached_ai_data)
			
			var player = Player.new(p_idx, p_name, false, ai_strategy)
			players.append(player)
			
			# Registrera att denna AI spelat en match (både totalt och för matchtypen)
			roster_stats[p_name]["matches_total"] += 1
			roster_stats[p_name]["matches_" + str(match_type)] += 1
			
		var sim_manager = SimulationManager.new(players)
		var result = await sim_manager.run_match(max_turns)
		
		if result["winner_name"] == "Draw":
			draws += 1
		else:
			var winner = result["winner_name"]
			# Registrera vinst (både totalt och för matchtypen)
			roster_stats[winner]["wins_total"] += 1
			roster_stats[winner]["wins_" + str(match_type)] += 1
			
		progress_bar.value = i + 1
		if i % 50 == 0:
			await get_tree().process_frame
			
	# 4. SAMMANSTÄLL LEADERBOARD
	var end_time = Time.get_ticks_msec()
	var time_taken = (end_time - start_time) / 1000.0
	
	var leaderboard = []
	for p_name in roster_stats.keys():
		leaderboard.append({
			"name": p_name,
			"stats": roster_stats[p_name] # Flyttade hela datan in hit för att göra matten renare nedan
		})
		
	# Sortera listan efter flest vinster totalt!
	leaderboard.sort_custom(func(a, b): return a["stats"]["wins_total"] > b["stats"]["wins_total"])
	
	# 5. SKRIV UT DEN DYNAMISKA POÄNGTAVLAN
	var text = "[center][b]--- TOURNAMENT LEADERBOARD ---[/b][/center]\n"
	text += "Total Matches: " + str(total_matches) + " | Time: " + str(time_taken).pad_decimals(2) + "s | Draws: " + str(draws) + "\n\n"
	
	# Räkna ut hur många kolumner tabellen behöver
	var num_cols = 4
	var show_details = active_types.size() > 1
	if show_details:
		num_cols += active_types.size()
		
	text += "[table=" + str(num_cols) + "]\n"
	text += "[cell][b] Rank [/b][/cell][cell][b] AI Profile [/b][/cell][cell][b] Wins [/b][/cell][cell][b] Total Win % [/b][/cell]"
	
	# Lägg till extra rubriker om vi kör flera matchtyper
	if show_details:
		if 2 in active_types: text += "[cell][b] 2-Player % [/b][/cell]"
		if 3 in active_types: text += "[cell][b] 3-Player % [/b][/cell]"
		if 4 in active_types: text += "[cell][b] 4-Player % [/b][/cell]"
		
	# Smart mini-funktion (Lambda) som räknar ut procent och undviker division med noll
	var get_rate = func(wins, matches): 
		if matches == 0: return "-"
		return str((float(wins) / float(matches)) * 100.0).pad_decimals(1) + "%"
	
	for i in range(leaderboard.size()):
		var p = leaderboard[i]
		var s = p["stats"]
		
		# Fyll i grund-datan
		text += "[cell]" + str(i + 1) + ". [/cell]"
		text += "[cell]" + p["name"] + "   [/cell]"
		text += "[cell]" + str(s["wins_total"]) + "   [/cell]"
		text += "[cell]" + get_rate.call(s["wins_total"], s["matches_total"]) + "[/cell]"
		
		# Fyll i extradatat om det finns
		if show_details:
			if 2 in active_types: text += "[cell]" + get_rate.call(s["wins_2"], s["matches_2"]) + "[/cell]"
			if 3 in active_types: text += "[cell]" + get_rate.call(s["wins_3"], s["matches_3"]) + "[/cell]"
			if 4 in active_types: text += "[cell]" + get_rate.call(s["wins_4"], s["matches_4"]) + "[/cell]"
			
	text += "[/table]"
	
	results_label.text = text

# Den här funktionen bygger hela match-kön!
func _generate_matchups(ai_indices: Array, players_per_match: int) -> Array:
	var matchups = []
	_combine_helper(ai_indices, players_per_match, 0, [], matchups)
	return matchups

# Detta är en rekursiv algoritm (matematik-magi) som hittar alla unika kombinationer
func _combine_helper(arr: Array, k: int, start_idx: int, current_combo: Array, result: Array):
	if current_combo.size() == k:
		result.append(current_combo.duplicate())
		return
		
	for i in range(start_idx, arr.size()):
		current_combo.append(arr[i])
		_combine_helper(arr, k, i + 1, current_combo, result)
		current_combo.pop_back()

func _on_available_list_selected(_index: int):
	selected_ai_list.deselect_all() # Klickar du till vänster, avmarkera till höger

func _on_selected_list_selected(_index: int):
	available_ai_list.deselect_all() # Klickar du till höger, avmarkera till vänster

# En smart hjälp-funktion för att veta vilken AI som är vald just nu
func _get_selected_ai_index() -> int:
	# Kollar om något är valt i vänstra listan
	if available_ai_list.get_selected_items().size() > 0:
		var selected_row = available_ai_list.get_selected_items()[0]
		return available_ai_list.get_item_metadata(selected_row)
		
	# Kollar om något är valt i högra listan
	elif selected_ai_list.get_selected_items().size() > 0:
		var selected_row = selected_ai_list.get_selected_items()[0]
		return selected_ai_list.get_item_metadata(selected_row)
		
	return -1 # Inget var valt

func _add_ai_to_roster(amount: int):
	var ai_index = _get_selected_ai_index()
	if ai_index == -1:
		return # Avbryt om ingen AI är markerad
		
	var ai_name = available_ais[ai_index]["name"]
	
	for i in range(amount):
		var new_row = selected_ai_list.add_item(ai_name)
		selected_ai_list.set_item_metadata(new_row, ai_index)
		
	# Skrolla automatiskt ner till det vi just lade till!
	selected_ai_list.ensure_current_is_visible()
	_update_math()

func _on_add_one_pressed():
	_add_ai_to_roster(1)
	_update_math()

func _on_add_five_pressed():
	_add_ai_to_roster(5)
	_update_math()

func _on_remove_all_selected_pressed():
	var ai_index = _get_selected_ai_index()
	if ai_index == -1:
		return
		
	# När man tar bort saker ur en lista MÅSTE man loopa baklänges!
	# Annars ändras indexen på raderna medan man tar bort dem.
	for i in range(selected_ai_list.item_count - 1, -1, -1):
		if selected_ai_list.get_item_metadata(i) == ai_index:
			selected_ai_list.remove_item(i)
	_update_math()

func _on_clear_selected_list_pressed():
	selected_ai_list.clear()
	_update_math()

# --- DOUBLE CLICK LOGIC ---

func _on_available_list_activated(_index: int):
	# Dubbelklick till vänster lägger till 1
	_add_ai_to_roster(1)
	_update_math()

func _on_selected_list_activated(index: int):
	# Dubbelklick till höger tar exakt BORT den raden man klickade på
	selected_ai_list.remove_item(index)
	_update_math()

# --- ROUND ROBIN MATH CALCULATOR ---
func _update_math():
	# 1. Inställningar och grundkoll
	var n = selected_ai_list.item_count
	var total_matches = 0
	var max_limit = 15000 # NYTT: Ändra maxgränsen enkelt här!
	
	var is_any_type_selected = two_player_checkbox.button_pressed or three_player_checkbox.button_pressed or four_player_checkbox.button_pressed
	
	if not is_any_type_selected:
		no_selected_label.text = "Please select at least one match type!"
		no_selected_label.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		no_selected_label.text = " " 
		
	# 2. Räkna ut bas-matcherna och simulera multiplikatorn!
	if is_any_type_selected and n >= 2:
		var q2_size = 0
		var q3_size = 0
		var q4_size = 0
		
		var ai_matches_2 = 0.0
		var ai_matches_3 = 0.0
		var ai_matches_4 = 0.0
		var max_matches_per_ai = 0.0
		
		# A: Hitta hur stora köerna är och hur mycket en enskild AI spelar i dem
		if two_player_checkbox.button_pressed and n >= 2:
			q2_size = (n * (n - 1)) / 2
			ai_matches_2 = float(q2_size * 2) / float(n)
			max_matches_per_ai = max(max_matches_per_ai, ai_matches_2)
			
		if three_player_checkbox.button_pressed and n >= 3:
			q3_size = (n * (n - 1) * (n - 2)) / 6
			ai_matches_3 = float(q3_size * 3) / float(n)
			max_matches_per_ai = max(max_matches_per_ai, ai_matches_3)
			
		if four_player_checkbox.button_pressed and n >= 4:
			q4_size = (n * (n - 1) * (n - 2) * (n - 3)) / 24
			ai_matches_4 = float(q4_size * 4) / float(n)
			max_matches_per_ai = max(max_matches_per_ai, ai_matches_4)
			
		# B: Applicera multiplikatorn (exakt som turneringen gör!)
		var base_matchups = 0
		if q2_size > 0:
			var mult2 = max(1, round(max_matches_per_ai / ai_matches_2))
			base_matchups += q2_size * mult2
			
		if q3_size > 0:
			var mult3 = max(1, round(max_matches_per_ai / ai_matches_3))
			base_matchups += q3_size * mult3
			
		if q4_size > 0:
			var mult4 = max(1, round(max_matches_per_ai / ai_matches_4))
			base_matchups += q4_size * mult4
			
		# C: Lägg på användarens egna repetitioner
		var repetitions = int(matchup_number_spin_box.value)
		total_matches = base_matchups * repetitions
	
	# 3. Uppdatera texten på skärmen dynamiskt
	total_match_number_label.text = "Total matches: " + str(total_matches) + " / " + str(max_limit)
	
	# 4. Säkerhetsspärrar
	if match_mode_dropdown.selected == 1: # Kollar om vi befinner oss i Round Robin-läget
		if total_matches == 0 or total_matches > max_limit or not is_any_type_selected:
			start_button.disabled = true
			if total_matches > max_limit:
				total_match_number_label.add_theme_color_override("font_color", Color(1, 0, 0)) # Röd varning
			else:
				total_match_number_label.remove_theme_color_override("font_color")
		else:
			start_button.disabled = false
			total_match_number_label.remove_theme_color_override("font_color")
# --- SETTINGS SAVE/LOAD LOGIC ---

func _save_sim_settings():
	GameSettings.sim_settings["match_mode"] = match_mode_dropdown.selected
	
	# Spara Repeated Matchup
	GameSettings.sim_settings["repeated"]["num_players_idx"] = num_players_opt.selected
	GameSettings.sim_settings["repeated"]["num_matches"] = match_count_spinbox.value
	GameSettings.sim_settings["repeated"]["max_turns"] = repeated_max_turns_spinbox.value
	GameSettings.sim_settings["repeated"]["randomize_seats"] = randomize_seats_checkbox.button_pressed
	
	var slots = [slot1_opt, slot2_opt, slot3_opt, slot4_opt]
	for i in range(4):
		var menu = slots[i]
		if menu.selected != -1 and available_ais.size() > 0:
			var ai_index = menu.get_item_metadata(menu.selected)
			GameSettings.sim_settings["repeated"]["slots"][i] = available_ais[ai_index]["name"]
			
	# Spara Round Robin
	GameSettings.sim_settings["round_robin"]["types"] = [
		two_player_checkbox.button_pressed,
		three_player_checkbox.button_pressed,
		four_player_checkbox.button_pressed
	]
	GameSettings.sim_settings["round_robin"]["repetitions"] = matchup_number_spin_box.value
	GameSettings.sim_settings["round_robin"]["max_turns"] = round_robin_max_turns_spinbox.value
	
	var selected_ai_names = []
	for i in range(selected_ai_list.item_count):
		var ai_index = selected_ai_list.get_item_metadata(i)
		selected_ai_names.append(available_ais[ai_index]["name"])
	GameSettings.sim_settings["round_robin"]["selected_ais"] = selected_ai_names

func _load_sim_settings():
	# Ladda Match Mode
	match_mode_dropdown.selected = GameSettings.sim_settings["match_mode"]
	_on_match_mode_changed( GameSettings.sim_settings["match_mode"])
	
	# Ladda Repeated Matchup
	num_players_opt.selected = GameSettings.sim_settings["repeated"]["num_players_idx"]
	match_count_spinbox.value = GameSettings.sim_settings["repeated"]["num_matches"]
	repeated_max_turns_spinbox.value = GameSettings.sim_settings["repeated"]["max_turns"]
	randomize_seats_checkbox.button_pressed = GameSettings.sim_settings["repeated"]["randomize_seats"]
	
	var slots = [slot1_opt, slot2_opt, slot3_opt, slot4_opt]
	for i in range(4):
		var saved_name = GameSettings.sim_settings["repeated"]["slots"][i]
		if saved_name != "":
			_select_option_by_name(slots[i], saved_name)
			
	# Ladda Round Robin
	var types = GameSettings.sim_settings["round_robin"]["types"]
	two_player_checkbox.button_pressed = types[0]
	three_player_checkbox.button_pressed = types[1]
	four_player_checkbox.button_pressed = types[2]
	
	matchup_number_spin_box.value = GameSettings.sim_settings["round_robin"]["repetitions"]
	round_robin_max_turns_spinbox.value = GameSettings.sim_settings["round_robin"]["max_turns"]
	
	# Ladda Turneringslistan SÄKERT
	selected_ai_list.clear()
	for saved_name in GameSettings.sim_settings["round_robin"]["selected_ais"]:
		var ai_index = _get_ai_index_by_name(saved_name)
		# Lägg bara till den i listan om filen faktiskt fortfarande finns!
		if ai_index != -1:
			var new_row = selected_ai_list.add_item(saved_name)
			selected_ai_list.set_item_metadata(new_row, ai_index)
	_update_math()

# Smarta hjälpfunktioner för att leta upp AI baserat på Namn istället för id-nummer
func _select_option_by_name(menu: OptionButton, ai_name: String):
	for i in range(menu.item_count):
		var ai_index = menu.get_item_metadata(i)
		if available_ais[ai_index]["name"] == ai_name:
			menu.selected = i
			return
	menu.selected = 0 # Fallback om den raderats

func _get_ai_index_by_name(ai_name: String) -> int:
	for i in range(available_ais.size()):
		if available_ais[i]["name"] == ai_name:
			return i
	return -1 # Betyder att AI:n blivit raderad/omdöpt

func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
	_save_sim_settings()
