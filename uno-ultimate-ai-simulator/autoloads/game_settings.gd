extends Node

# Definitioner för de fyra platserna
# Varje plats har: aktiv, är_människa, visa_kort, ai_fil
var slots = {
	"bottom": {"active": true, "is_human": true,  "show_cards": true,  "ai_name": "Spelare"},
	"left":   {"active": true, "is_human": false, "show_cards": false, "ai_name": "AI Vänster"},
	"top":    {"active": true, "is_human": false, "show_cards": false, "ai_name": "AI Topp"},
	"right":  {"active": true, "is_human": false, "show_cards": false, "ai_name": "AI Höger"}
}

var game_speed: float = 1.0 # 1.0 = normal, 2.0 = dubbel hastighet, etc.

# Hjälpfunktion för att få fram antal aktiva spelare
func get_active_player_count() -> int:
	var count = 0
	for s in slots.values():
		if s.active: count += 1
	return count
