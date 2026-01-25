extends Node

func _ready():
	var players: Array[Player] = [
		Player.new(1),
		Player.new(2)
	]
	var game = UnoGame.new(players)

	print("Starting discard:", game.state.discard_pile[-1].card_to_string())
	for i in range(5):
		var player = game.state.players[game.state.current_player_index]
		var card = player.hand[0]  # play first card in hand
		game.play_card(player, card)
