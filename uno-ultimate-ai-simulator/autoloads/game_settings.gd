extends Node

var ai_path1 = "res://ai_profiles/simple_ai.json"

var slots = {
	"bottom": {"active": true, "is_human": true, "show_cards": true, "ai_name": "You", "ai_path": ai_path1},
	"left":   {"active": true, "is_human": false, "show_cards": false, "ai_name": "AI: Test", "ai_path": ai_path1},
	"top":    {"active": true, "is_human": false, "show_cards": false, "ai_name": "AI: Test", "ai_path": ai_path1},
	"right":  {"active": true, "is_human": false, "show_cards": false, "ai_name": "AI: Test", "ai_path": ai_path1}
}

var max_turns: int = 500
var game_speed: float = 1.0

# Berättar om vi spelar på riktigt eller bara testar i editorn
var is_test_mode: bool = false

func get_active_player_count() -> int:
	var count = 0
	for s in slots.values():
		if s.active: count += 1
	return count

# --- MULTIPLE GAMES (SIMULATION) SETTINGS ---
var sim_settings = {
	"match_mode": 0,
	"repeated": {
		"num_players_idx": 2, # Index 2 = 4 players
		"num_matches": 100,
		"max_turns": 500,
		"randomize_seats": false,
		"slots": ["", "", "", ""] # Här sparar vi AI-namnen
	},
	"round_robin": {
		"types": [false, false, true], # 2, 3, 4 player checkboxar
		"repetitions": 1,
		"max_turns": 500,
		"selected_ais": [] # Här sparar vi en lista med AI-namn
	}
}
