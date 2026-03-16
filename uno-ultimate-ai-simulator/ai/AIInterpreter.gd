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
		return _execute_action(node.get("name", ""), view)
	
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
			
		"has_playable_attack_card":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					if card.value in [Card.CardValue.SKIP, Card.CardValue.REVERSE, Card.CardValue.DRAW_TWO, Card.CardValue.WILD_DRAW_FOUR]:
						return true
			return false
			
		"has_wild_card":
			for card in view.own_hand:
				if card.color == Card.CardColor.WILD:
					return true
			return false
			
		"chance":
			# Om vi har en "chance"-nod, läser vi värdet från JSON (standard 50%)
			var threshold = node.get("value", 50)
			return (randi() % 100) < threshold
			
	return false

# --- LOGIKEN FÖR HANDLINGAR (ACTIONS) ---
func _execute_action(action_name: String, view: PlayerView) -> PlayerAction:
	match action_name:
		"play_first_playable":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					return _create_action_with_color(card)
					
		"play_playable_attack_card":
			for card in view.own_hand:
				if card.is_playable_on(view.top_discard, view.current_color):
					if card.value in [Card.CardValue.SKIP, Card.CardValue.REVERSE, Card.CardValue.DRAW_TWO, Card.CardValue.WILD_DRAW_FOUR]:
						return _create_action_with_color(card)
		
		"draw_card":
			return PlayerAction.new(null)
			
	return PlayerAction.new(null) # Standard: dra kort

# Hjälpfunktion för att hantera färgval om kortet är WILD
func _create_action_with_color(card: Card) -> PlayerAction:
	var color = card.color
	if card.color == Card.CardColor.WILD:
		# Enkel logik för nu: Slumpa färg
		var colors = [Card.CardColor.RED, Card.CardColor.GREEN, Card.CardColor.BLUE, Card.CardColor.YELLOW]
		color = colors.pick_random()
	
	return PlayerAction.new(card, color)
