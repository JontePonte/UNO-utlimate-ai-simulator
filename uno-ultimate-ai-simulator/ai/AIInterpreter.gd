extends AIPlayer
class_name AIInterpreter

# AI:ns inlästa "hjärna"
var brain_data: Dictionary = {}
var current_file_path: String = "" # <-- NY: Håller koll på vår fil

func load_profile(file_path: String):
	current_file_path = file_path # Spara sökvägen
	
	if not FileAccess.file_exists(file_path): 
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_text = file.get_as_text()
	var json_data = JSON.parse_string(json_text)
	
	if json_data:
		load_from_data(json_data)
		
	# --- NYTT: Börja lyssna på uppdateringar om vi inte redan gör det ---
	if not AiManager.ai_profile_saved.is_connected(_on_ai_profile_saved):
		AiManager.ai_profile_saved.connect(_on_ai_profile_saved)

# --- NY FUNKTION: Byt hjärna i realtid ---
func _on_ai_profile_saved(saved_file_name: String, new_data: Dictionary):
	# Kolla så att det är VÅR fil som har sparats (ifall det finns andra AI i matchen)
	if current_file_path.ends_with(saved_file_name):
		print(ai_name + " fick en live-uppdatering av sin hjärna!")
		load_from_data(new_data) # Ladda in det nya trädet!

func load_from_data(data: Dictionary):
	brain_data = data
	ai_name = brain_data.get("ai_name", "Unknown AI")

# Grundfunktionen som anropas av SimulationManager/GameManager
func choose_action(view: PlayerView) -> PlayerAction:
	if brain_data.is_empty() or not brain_data.has("root"):
		return PlayerAction.new(null) # Fallback: dra kort
	
	# Vi börjar vandra i trädet från root
	return _process_node(brain_data["root"], view)

# Den rekursiva funktionen som vandrar genom trädet
func _process_node(node: Dictionary, view: PlayerView) -> PlayerAction:
	
	# --- STEG 2.5: SKRIK I MEGAFONEN! ---
	# Om noden har ett sparat namn från editorn, skicka ut det!
	if node.has("editor_node"):
		AiManager.ai_node_executing.emit(node["editor_node"])
	# ------------------------------------
	
	var type = node.get("type", "")
	
	# 1. Om vi nått en handling (Action)
	if type == "action":
		return _execute_action(node, view)
	
	# 2. Om vi nått ett villkor (Condition)
	elif type == "condition":
		var condition_name = node.get("name", "")
		var result = _evaluate_condition(condition_name, view, node)
		
		if result:
			return _process_node(node["true_branch"], view)
		else:
			return _process_node(node["false_branch"], view)
			
	# Säkerhetsspärr om JSON-filen är felbyggd
	return PlayerAction.new(null)

# --- LOGIKEN FÖR FRÅGOR (CONDITIONS) ---
func _evaluate_condition(condition_name: String, view: PlayerView, node: Dictionary) -> bool:
	match condition_name:
		"can_play_any_card":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					return true
			return false
		
		"has_playable_special_card":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					# Alla kort som inte är vanliga siffror räknas som special
					if card.value in [Card.CardValue.SKIP, Card.CardValue.REVERSE, Card.CardValue.DRAW_TWO, Card.CardValue.WILD_DRAW_FOUR] or card.color == Card.CardColor.WILD:
						return true
			return false
			
		"has_playable_attack_card":
			var is_two_player = view.card_counts.size() == 2
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					# +2, Skip och +4 är alltid attacker
					var is_attack = card.value in [Card.CardValue.SKIP, Card.CardValue.DRAW_TWO, Card.CardValue.WILD_DRAW_FOUR]
					# Reverse är BARA en attack om man är 2 spelare
					if is_two_player and card.value == Card.CardValue.REVERSE:
						is_attack = true
						
					if is_attack:
						return true
			return false
		
		"can_play_same_color":
			for card in view.own_hand:
				# Vi letar efter ett kort som matchar spelets nuvarande färg.
				# Vi ignorerar Wild-kort här (de spelas ju när man VILL byta färg).
				if card.color == view.current_color and card.color != Card.CardColor.WILD:
					# Säkerhetskoll att det faktiskt är ett giltigt drag
					if card.is_playable_on(view.top_discard, view.current_color):
						return true
			return false
			
		"can_play_same_number":
			for card in view.own_hand:
				# Vi vill bara matcha siffror/symboler om det översta kortet INTE är ett Wild-kort
				if view.top_discard.color != Card.CardColor.WILD:
					if card.value == view.top_discard.value:
						if card.is_playable_on(view.top_discard, view.current_color):
							return true
			return false
			
		"has_uno":
			# "UNO" betyder ju att man sitter med exakt 1 kort på handen.
			# Om du hellre vill att AI:n ska reagera precis INNAN den får UNO 
			# (t.ex. för att skrika "UNO!" när den lägger sitt näst sista kort), 
			# kan du ändra detta till: return view.own_hand.size() == 2
			return view.own_hand.size() == 1
		
		"can_play_wild":
			for card in view.own_hand:
				# Kollar så det är en vanlig Wild (inte +4)
				if card.color == Card.CardColor.WILD and card.value != Card.CardValue.WILD_DRAW_FOUR:
					return true
			return false
			
		"can_play_wild_draw_four":
			for card in view.own_hand:
				if card.color == Card.CardColor.WILD and card.value == Card.CardValue.WILD_DRAW_FOUR:
					return true
			return false
			
		"can_play_draw_two":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color) and card.value == Card.CardValue.DRAW_TWO:
					return true
			return false
			
		"can_play_skip":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color) and card.value == Card.CardValue.SKIP:
					return true
			return false
			
		"can_play_reverse":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color) and card.value == Card.CardValue.REVERSE:
					return true
			return false
		"compare_table_color":
			var target_rank = int(node.get("rank_choice", 0))
			var tied_colors = _get_tied_color_ranking(view.own_hand)
			
			if target_rank >= 0 and target_rank < tied_colors.size():
				return tied_colors[target_rank].has(view.current_color)
				
			return false
		
		"check_player_count":
			# Valen var: 0="2", 1="3", 2="4"
			var choice = int(node.get("player_count_choice", 0))
			var target_count = choice + 2
			return view.card_counts.size() == target_count
		
		"check_playable_card_count":
			# Räkna hur många kort vi kan spela just nu
			var playable_count = 0
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					playable_count += 1
			
			var choice = int(node.get("card_count_choice", 0))
			# Valen var: 0="Only One", 1="Multiple", 2="None"
			if choice == 0: return playable_count == 1
			elif choice == 1: return playable_count > 1
			elif choice == 2: return playable_count == 0
			return false
		
		"compare_opponent_hand":
			var target = int(node.get("opponent_target", 0))
			var condition = int(node.get("opponent_condition", 0))
			
			var my_count = view.own_hand.size()
			var total_players = view.card_counts.size()
			var opponents_to_check = []
			
			# 1. Bestäm VILKA motståndare vi ska titta på
			if target == 0: # Next Player
				# posmod hanterar minusvärden perfekt om play_direction är -1 (Reverse)
				var next_idx = posmod(view.player_index + view.play_direction, total_players)
				opponents_to_check.append(view.card_counts[next_idx])
				
			elif target == 1: # Previous Player
				var prev_idx = posmod(view.player_index - view.play_direction, total_players)
				opponents_to_check.append(view.card_counts[prev_idx])
				
			elif target == 2: # Any Player (Alla utom vi själva)
				for i in range(total_players):
					if i != view.player_index:
						opponents_to_check.append(view.card_counts[i])
						
			elif target == 3: # Player with most cards
				var max_cards = -1
				for i in range(total_players):
					if i != view.player_index and view.card_counts[i] > max_cards:
						max_cards = view.card_counts[i]
				opponents_to_check.append(max_cards)
				
			elif target == 4: # Player with least cards
				var min_cards = 999
				for i in range(total_players):
					if i != view.player_index and view.card_counts[i] < min_cards:
						min_cards = view.card_counts[i]
				opponents_to_check.append(min_cards)
				
			# 2. Testa villkoret på de utvalda motståndarna
			for opp_count in opponents_to_check:
				var match_found = false
				
				# Valen var: 0="less", 1="more", 2="equal", 3="1 or 2", 4="UNO"
				if condition == 0: match_found = (opp_count < my_count)
				elif condition == 1: match_found = (opp_count > my_count)
				elif condition == 2: match_found = (opp_count == my_count)
				elif condition == 3: match_found = (opp_count <= 2)
				elif condition == 4: match_found = (opp_count == 1)
				
				# Om vi hittar NÅGON som matchar (viktigt för "Any Player"), returnera True!
				if match_found:
					return true
					
			return false
	return false

# --- LOGIKEN FÖR HANDLINGAR (ACTIONS) ---
func _execute_action(node: Dictionary, view: PlayerView) -> PlayerAction:
	var action_name = node.get("name", "")
	
	match action_name:
		"play_first_playable":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					return _create_action_with_color(card, view, 0)
		"play_first_special_card":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					if card.value in [Card.CardValue.SKIP, Card.CardValue.REVERSE, Card.CardValue.DRAW_TWO, Card.CardValue.WILD_DRAW_FOUR] or card.color == Card.CardColor.WILD:
						# Om det råkar vara ett Wild-kort, låter vi spelet automatiskt välja vår bästa färg (0)
						return _create_action_with_color(card, view, 0)
						
		"play_first_attack_card":
			var is_two_player = view.card_counts.size() == 2
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					var is_attack = card.value in [Card.CardValue.SKIP, Card.CardValue.DRAW_TWO, Card.CardValue.WILD_DRAW_FOUR]
					if is_two_player and card.value == Card.CardValue.REVERSE:
						is_attack = true
						
					if is_attack:
						# Om det råkar vara en +4, låter vi spelet automatiskt välja vår bästa färg
						return _create_action_with_color(card, view, 0)		
		
		"play_wild":
			for card in view.own_hand:
				if card.color == Card.CardColor.WILD and card.value != Card.CardValue.WILD_DRAW_FOUR:
					var color_choice = int(node.get("color_choice", 0))
					return _create_action_with_color(card, view, color_choice)
					
		"play_wild_draw_four":
			for card in view.own_hand:
				if card.color == Card.CardColor.WILD and card.value == Card.CardValue.WILD_DRAW_FOUR:
					var color_choice = int(node.get("color_choice", 0))
					return _create_action_with_color(card, view, color_choice)
					
		"play_draw_two":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color) and card.value == Card.CardValue.DRAW_TWO:
					return _create_action_with_color(card, view, 0)
					
		"play_skip":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color) and card.value == Card.CardValue.SKIP:
					return _create_action_with_color(card, view, 0)
					
		"play_reverse":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color) and card.value == Card.CardValue.REVERSE:
					return _create_action_with_color(card, view, 0)
					
		"play_same_color":
			for card in view.own_hand:
				if card.color == view.current_color and card.color != Card.CardColor.WILD:
					if card.is_playable_on(view.top_discard, view.current_color):
						return _create_action_with_color(card, view, 0)
						
		"play_same_number":
			for card in view.own_hand:
				if view.top_discard.color != Card.CardColor.WILD:
					if card.value == view.top_discard.value:
						if card.is_playable_on(view.top_discard, view.current_color):
							return _create_action_with_color(card, view, 0)
							
		"draw_card":
			return PlayerAction.new(null)
			
	return PlayerAction.new(null)

func _create_action_with_color(card: Card, view: PlayerView, color_rank: int) -> PlayerAction:
	var color = card.color
	
	if card.color == Card.CardColor.WILD:
		var ranked_colors = _get_color_ranking(view.own_hand)
		
		# Kolla så att rankingen är giltig (0 till 3)
		if color_rank >= 0 and color_rank < ranked_colors.size():
			color = ranked_colors[color_rank]
		else:
			color = ranked_colors[0] # Fallback till bästa färgen
			
	return PlayerAction.new(card, color)

# --- HJÄLPFUNKTION: Rangordna färgerna på handen ---
func _get_color_ranking(hand: Array) -> Array:
	var counts = {
		Card.CardColor.RED: 0, Card.CardColor.GREEN: 0,
		Card.CardColor.BLUE: 0, Card.CardColor.YELLOW: 0
	}
	for card in hand:
		if card.color in counts:
			counts[card.color] += 1
	var ranked_colors = counts.keys()
	ranked_colors.sort_custom(func(a, b): return counts[a] > counts[b])
	return ranked_colors

func _get_tied_color_ranking(hand: Array) -> Array:
	var counts = {
		Card.CardColor.RED: 0, Card.CardColor.GREEN: 0,
		Card.CardColor.BLUE: 0, Card.CardColor.YELLOW: 0
	}
	
	for card in hand:
		if card.color in counts:
			counts[card.color] += 1
			
	var sorted_counts = counts.values()
	sorted_counts.sort()
	sorted_counts.reverse() 
	
	var tied_ranks = []
	
	for target_count in sorted_counts:
		var colors_for_this_rank = []
		for color in counts.keys():
			if counts[color] == target_count:
				colors_for_this_rank.append(color)
		tied_ranks.append(colors_for_this_rank)
		
	return tied_ranks
