class_name PlayerView

# Index of the player this view belongs to
var player_index: int

# The player's own hand (copy, not reference to original array)
var own_hand: Array[Card] = []

# Top card of the discard pile
var top_discard: Card

# All previous moves
var move_history: Array[Move]

# Number of cards each player currently holds
var opponent_card_counts: Array[int]

# Index of current player
var current_player_index: int

# Direction of play (1 or -1)
var play_direction: int

# Turn counter (optional but useful for AI logic)
var turn_number: int


func _init(
	_player_index: int,
	_own_hand: Array[Card],
	_top_discard: Card,
	_opponent_card_counts: Array[int],
	_current_player_index: int,
	_play_direction: int,
	_turn_number: int,
	_move_history: Array[Move]
):
	player_index = _player_index
	own_hand = _own_hand
	top_discard = _top_discard
	opponent_card_counts = _opponent_card_counts
	current_player_index = _current_player_index
	play_direction = _play_direction
	turn_number = _turn_number
	move_history = _move_history
