class_name Player

var id: int
var hand: Array[Card] = []
var is_human: bool = true
var ai_controller: AIPlayer = null


func _init(_id: int, _is_human := true, _ai_controller: AIPlayer = null):
	id = _id
	is_human = _is_human
	ai_controller = _ai_controller
