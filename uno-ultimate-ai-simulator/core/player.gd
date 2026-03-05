class_name Player
extends RefCounted

var index: int
var name: String
var is_human: bool
var ai_controller # T.ex. din AISimple
var hand: Array[Card] = []

func _init(_index: int, _name: String, _is_human: bool, _ai_controller = null):
	index = _index
	name = _name
	is_human = _is_human
	ai_controller = _ai_controller

# Detta är funktionen GameManager nu ropar på!
func take_turn(view: PlayerView) -> PlayerAction:
	if is_human:
		# Här kommer vi senare pausa koden och vänta på att människan klickar i UI:t!
		# För tillfället gör vi bara en minipaus och returnerar null (drar ett kort)
		await Engine.get_main_loop().process_frame 
		return null
	else:
		# Om det är en AI, skicka frågan direkt till elevens beslutsträd!
		if ai_controller != null:
			return ai_controller.choose_action(view)
		return null
