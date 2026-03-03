class_name PlayerAction
extends RefCounted

var card: Card
var declared_color: Card.CardColor

func _init(_card: Card = null, _declared_color: Card.CardColor = Card.CardColor.RED):
	card = _card
	declared_color = _declared_color
