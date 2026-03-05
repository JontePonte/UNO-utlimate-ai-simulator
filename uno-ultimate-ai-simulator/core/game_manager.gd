class_name GameManager
extends Node # <-- OBS! Måste ärva från Node nu för att kunna använda Godots timer (get_tree().create_timer)

# --- SIGNALER FÖR UI ---
signal card_dealt(player_index: int, card: Card)
signal card_played(player_index: int, card: Card, declared_color: Card.CardColor)
signal card_drawn(player_index: int, card: Card)
signal turn_started(player_index: int)
signal game_over(winner_index: int)

var state: GameState
var rules: Rules

var START_CARD_AMOUNT = 7

# --- VISUELLA INSTÄLLNINGAR ---
var visual_mode: bool = false
var turn_delay: float = 1.0 # Antal sekunder vi pausar mellan dragen om visual_mode är true

func _init(_players: Array[Player], _rules := Rules.new()):
	state = GameState.new()
	state.players = _players
	rules = _rules

	# Skapa och shuffle deck
	state.draw_pile = Deck.new()
	state.draw_pile.shuffle()

	# Start discard pile
	state.discard_pile = []

	# Initial deal
	deal_initial_hands(START_CARD_AMOUNT)
	start_discard_pile()


func deal_initial_hands(cards_per_player: int):
	for player in state.players:
		var player_idx = state.players.find(player)
		for i in range(cards_per_player):
			var card = state.draw_pile.draw()
			if card != null:
				player.hand.append(card)
				card_dealt.emit(player_idx, card) # Meddela UI!


func start_discard_pile():
	var card = state.draw_pile.draw()
	
	# If first card is WILD_DRAW_FOUR take another
	while card.value == Card.CardValue.WILD_DRAW_FOUR:
		state.draw_pile.cards.append(card)
		state.draw_pile.shuffle()
		card = state.draw_pile.draw()

	state.discard_pile.append(card)


# --- TURN MANAGEMENT ---
func process_turn():
	var player = state.players[state.current_player_index]
	var player_view = create_player_view(state.current_player_index)
	
	turn_started.emit(state.current_player_index) # Meddela UI vems tur det är!
	
	# PAUSA HÄR: Vi väntar på att spelaren (oavsett om det är AI eller Människa) gör sitt drag
	var action: PlayerAction = await player.take_turn(player_view)
	
	# Kolla om paketet innehåller ett kort att spela
	if action != null and action.card != null:
		play_card(state.current_player_index, action.card, action.declared_color)
	else:
		# Om card är null betyder det att vi måste dra ett kort
		draw_cards(state.current_player_index, 1)
	
	await next_player()
	state.turn_number += 1

func next_player():
	# Om ett SKIP-kort spelades, hoppar vi ett extra steg
	var steps = 1
	if state.pending_skip:
		steps = 2
		state.pending_skip = false # Återställ flaggan
		
	var num_players = state.players.size()
	state.current_player_index = (state.current_player_index + (state.play_direction * steps) + num_players) % num_players

	# Om vi kör en visuell match, ta en liten paus så åskådarna hinner med!
	if visual_mode:
		await get_tree().create_timer(turn_delay).timeout


# Run a full game between players for testing
func run_full_game(max_turns: int = 100):
	print("Spelet startar med ", state.players.size(), " spelare.")
	var turn_count = 0
	while turn_count < max_turns:
		# Nu använder vi await här också, eftersom process_turn pausar spelet i visual mode!
		await process_turn()
		
		# Kolla vinstkriterier
		for p in state.players:
			if p.hand.size() == 0:
				print("SPEL SLUT: ", p.name, " vann på tur ", turn_count)
				game_over.emit(state.players.find(p)) # Meddela UI att någon vann!
				return
				
		turn_count += 1
	print("Max turns nådda (", max_turns, "). Spelet slutade oavgjort.")


# --- PLAYER ACTIONS ---
func play_card(player_index: int, card: Card, declared_color: Card.CardColor = Card.CardColor.RED) -> bool:
	var player = state.players[player_index]
	
	player.hand.erase(card)
	state.discard_pile.append(card)

	if card.color == Card.CardColor.WILD:
		state.current_color = declared_color
	else:
		state.current_color = card.color
	
	_log_move(player_index, Move.MoveType.PLAY_CARD, card, declared_color)
	
	match card.value:
		Card.CardValue.SKIP:
			state.pending_skip = true
		Card.CardValue.REVERSE:
			if state.players.size() == 2:
				state.pending_skip = true
			else:
				state.play_direction *= -1
		Card.CardValue.DRAW_TWO:
			var next_idx = get_next_player_index_simple(1)
			draw_cards(next_idx, 2)
			state.pending_skip = true
		Card.CardValue.WILD_DRAW_FOUR:
			var next_idx = get_next_player_index_simple(1)
			draw_cards(next_idx, 4)
			state.pending_skip = true

	card_played.emit(player_index, card, declared_color) # Meddela UI!
	return true


# Hjälpfunktion för att titta framåt utan att ändra state
func get_next_player_index_simple(steps: int) -> int:
	var num_players = state.players.size()
	return (state.current_player_index + (state.play_direction * steps) + num_players) % num_players


func draw_cards(player_index: int, amount: int = 1):
	var player = state.players[player_index]
	
	for i in range(amount):
		# Kolla om plockhögen är tom (eller håller på att ta slut)
		if state.draw_pile.cards.size() == 0:
			_reshuffle_discard_into_draw()
			
		var card = state.draw_pile.draw()
		
		if card != null:
			player.hand.append(card)
			_log_move(player_index, Move.MoveType.DRAW_CARD, card)
			card_drawn.emit(player_index, card) # Meddela UI!
		else:
			print("Kritiskt fel: Inga kort finns kvar ens efter omblandning!")


# Helpfunction for reshuffle the drawdeck
func _reshuffle_discard_into_draw():
	# print("--- Reshuffle discard deck ---") 
	
	var top_card = state.discard_pile.pop_back()
	
	state.draw_pile.cards.append_array(state.discard_pile)
	state.discard_pile.clear()
	
	state.draw_pile.shuffle()
	
	if top_card != null:
		state.discard_pile.append(top_card)


func pass_turn(player_index: int):
	_log_move(player_index, Move.MoveType.PASS)


# --- MOVE LOGGING ---
func _log_move(player_index: int, move_type: Move.MoveType, card: Card = null, declared_color: Card.CardColor = Card.CardColor.RED):
	var move = Move.new(
		player_index,
		move_type,
		card,
		declared_color,
		state.turn_number
	)
	state.move_history.append(move)


# --- PLAYER VIEW ---
func create_player_view(player_index: int) -> PlayerView:
	var player = state.players[player_index]
	var top_card = state.discard_pile[-1]
	
	var card_counts: Array[int] = []
	for p in state.players:
		card_counts.append(p.hand.size())
	
	return PlayerView.new(
		player_index,
		player.hand.duplicate(),
		top_card,
		state.current_color, 
		card_counts.duplicate(),
		state.current_player_index,
		state.play_direction,
		state.turn_number,
		state.move_history.duplicate()
	)
