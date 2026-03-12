extends Node

enum AIType { SIMPLE, AGGRESSIVE, CUSTOM_FILE }

# Vi förenklar slotsen. Namnet används nu bara om det är en människa,
# annars hämtas det från AI-hjärnan.
var slots = {
	"bottom": {"active": true, "is_human": false,  "show_cards": false,  "ai_name": "Spelare 1", "ai_type": AIType.SIMPLE},
	"left":   {"active": true, "is_human": false, "show_cards": false, "ai_type": AIType.SIMPLE},
	"top":    {"active": true, "is_human": false, "show_cards": false, "ai_type": AIType.SIMPLE},
	"right":  {"active": true, "is_human": false, "show_cards": false, "ai_type": AIType.SIMPLE}
}

var max_turns: int = 500
var game_speed: float = 1.0

# Hjälpfunktion för att få fram antal aktiva spelare
func get_active_player_count() -> int:
	var count = 0
	for s in slots.values():
		if s.active: count += 1
	return count
