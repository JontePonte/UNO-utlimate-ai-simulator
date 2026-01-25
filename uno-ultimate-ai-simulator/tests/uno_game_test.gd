extends Node

func _ready():
	var players: Array[Player] = [
	Player.new(1),
	Player.new(2)
	]

	var game = UnoGame.new(players)

	# Print player hands
	for p in players:
		print("Player %d hand:" % p.id)
		for c in p.hand:
			print("- %s" % c.card_to_string())

	# Print to card in discard pile
	print("Discard pile top:", game.state.discard_pile[-1].card_to_string())
