class_name GameState

var players: Array[Player] = []
var current_player_index: int = 0
var play_direction: int = 1
var draw_pile: Deck
var discard_pile: Array[Card] = []

func get_current_player() -> Player:
	return players[current_player_index]
