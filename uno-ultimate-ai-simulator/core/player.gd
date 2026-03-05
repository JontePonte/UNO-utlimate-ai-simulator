class_name Player
extends RefCounted

signal human_action_made(action) # Måste matcha namnet på din action-klass (t.ex. PlayerAction)

var index: int
var name: String
var is_human: bool
var ai_controller
var hand: Array[Card] = []

func _init(_index: int, _name: String, _is_human: bool, _ai_controller = null):
	index = _index
	name = _name
	is_human = _is_human
	ai_controller = _ai_controller

func take_turn(view: PlayerView): # Ta bort typningen "-> PlayerAction" tillfälligt om det bråkar
	if is_human:
		var action = await self.human_action_made
		return action
	else:
		if ai_controller != null:
			return ai_controller.choose_action(view)
		return null
