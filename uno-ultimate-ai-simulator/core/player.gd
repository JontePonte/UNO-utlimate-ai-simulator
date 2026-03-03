class_name Player

var id: int
var name: String
var hand: Array[Card] = []
var is_human: bool = true
var ai_controller: AIPlayer = null


func _init(_id: int, _name: String = "", _is_human := true, _ai_controller: AIPlayer = null):
	id = _id
	name = _name
	is_human = _is_human
	ai_controller = _ai_controller

func hand_to_string() -> String:
	var s = ""
	for c in hand:
		s += c.card_to_string() + " "
	return s.strip_edges()
