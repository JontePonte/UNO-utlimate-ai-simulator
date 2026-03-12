extends Control

const AISimple = preload("res://ai/AISimple.gd")

@onready var num_players_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxL/NumberOfPlayers/OptionButton
@onready var slot3 = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot3
@onready var slot4 = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot4

@onready var match_count_spinbox = $MarginContainer/MainVBox/HBoxCenter/VBoxL/NumberOfMatches/SpinBox
@onready var slot1_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot1/OptionButton
@onready var slot2_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot2/OptionButton
@onready var slot3_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot3/OptionButton
@onready var slot4_opt = $MarginContainer/MainVBox/HBoxCenter/VBoxR/Slot4/OptionButton

@onready var start_button = $MarginContainer/MainVBox/Start
@onready var exit_button = $MarginContainer/MainVBox/ButtonHBox/ExitGame
@onready var main_menu_button = $MarginContainer/MainVBox/ButtonHBox/Back


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
		# 1. Ta reda på vilken AI som valts
		var ai_id = slots[i].get_item_id(slots[i].selected)
		var ai_strategy
		
		# Använd vår preloadade SimpleAI
		match ai_id:
			1: ai_strategy = AISimple.new()
			# 2: ai_strategy = AggressiveAI.new()
			_: ai_strategy = AISimple.new() # Fallback
			
		# 2. HÄR ÄR FIXEN FÖR FEL 1:
		# Vi skickar in (index, namn, is_human, ai_controller) direkt!
		var player_name = "Player " + str(i + 1)
		var player = Player.new(i, player_name, false, ai_strategy)
		
		players.append(player)
		
	return players

func _on_start_button_pressed():
	print("--- STARTAR SIMULERING ---")
	
	var num_matches = int(match_count_spinbox.value)
	var num_players = num_players_opt.get_item_id(num_players_opt.selected)
	
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
		
		# Vänta på att matchen ska bli klar
		var result = await sim_manager.run_match(1000) 
		
		# Registrera vinsten
		var winner = result["winner_name"]
		if scoreboard.has(winner):
			scoreboard[winner] += 1
		else:
			scoreboard[winner] = 1
			
	# --- SIMULERING KLAR ---
	var end_time = Time.get_ticks_msec()
	var time_taken = (end_time - start_time) / 1000.0
	
	print("--- SIMULERING KLAR PÅ ", time_taken, " SEKUNDER ---")
	print("Totalt antal matcher: ", num_matches)
	print("Resultat: ", scoreboard)

func _on_exit_button_pressed():
	get_tree().quit()

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://menus/MainMenu.tscn")
