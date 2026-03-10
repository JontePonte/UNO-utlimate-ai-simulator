extends Node

# Definitioner för platserna
var player_configs = {
	"bottom": {"is_human": true, "ai_file": "", "active": true, "show_cards": true},
	"top":    {"is_human": false, "ai_file": "default_ai.json", "active": true, "show_cards": false},
	"left":   {"is_human": false, "ai_file": "default_ai.json", "active": true, "show_cards": false},
	"right":  {"is_human": false, "ai_file": "default_ai.json", "active": true, "show_cards": false}
}

# Multiplikator för turn_delay
var game_speed = 1.0
