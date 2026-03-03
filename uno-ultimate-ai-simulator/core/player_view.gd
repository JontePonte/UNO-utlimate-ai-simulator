class_name PlayerView
extends RefCounted

var player_index: int
var own_hand: Array[Card]
var top_discard: Card
var current_color: Card.CardColor
var card_counts: Array[int]
var current_player: int
var play_direction: int
var turn_number: int
var move_history: Array[Move]

func _init(_player_index: int, _own_hand: Array[Card], _top_discard: Card, _current_color: Card.CardColor, _card_counts: Array[int], _current_player: int, _play_direction: int, _turn_number: int, _move_history: Array[Move]):
	player_index = _player_index
	own_hand = _own_hand
	top_discard = _top_discard
	current_color = _current_color
	card_counts = _card_counts
	current_player = _current_player
	play_direction = _play_direction
	turn_number = _turn_number
	move_history = _move_history
