class_name UnoGame

var state: GameState
var rules: Rules

func _init(_players: Array[Player], _rules := Rules.new()):
	state = GameState.new()
	state.players = _players
	rules = _rules
