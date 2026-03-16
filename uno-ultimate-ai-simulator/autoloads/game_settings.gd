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

func get_active_player_count() -> int:
	var count = 0
	for s in slots.values():
		if s.active: count += 1
	return count
