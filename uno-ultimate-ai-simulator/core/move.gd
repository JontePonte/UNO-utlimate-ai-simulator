class_name Move

enum MoveType {
	PLAY_CARD,
	DRAW_CARD,
	PASS
}

var player_index: int
var move_type: MoveType
var card: Card
var declared_color: Card.CardColor
var turn_number: int


func _init(
	_player_index: int,
	_move_type: MoveType,
	_card: Card = null,
	_declared_color: Card.CardColor = Card.CardColor.RED,
	_turn_number: int = 0
):
	player_index = _player_index
	move_type = _move_type
	card = _card
	declared_color = _declared_color
	turn_number = _turn_number
