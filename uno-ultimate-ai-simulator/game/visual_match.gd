extends Control

@onready var bottom_hand = $BottomHand
@onready var top_hand = $TopHand
@onready var left_hand = $LeftHand
@onready var right_hand = $RightHand

@export var card_ui_scene: PackedScene

@onready var draw_pile_node = $Table/DrawPile
@onready var discard_pile_node = $Table/DiscardPile

@onready var turn_arrow = $TurnArrow

@onready var bottom_name_label = $BottomNameLabel
@onready var top_name_label = $TopNameLabel
@onready var left_name_label = $LeftNameLabel
@onready var right_name_label = $RightNameLabel

@onready var game_over_overlay = $GameOverOverlay
@onready var winner_label = $GameOverOverlay/WinnerLabel
@onready var restart_button = $GameOverOverlay/VBoxContainer/PlayAgain
@onready var back_button = $GameOverOverlay/VBoxContainer/BackToArena
@onready var main_menu_button = $GameOverOverlay/VBoxContainer/MainMenu
@onready var exit_button = $GameOverOverlay/VBoxContainer/ExitGame

@onready var pause_overlay = $PauseOverlay
@onready var resume_button = $PauseOverlay/VBoxContainer/ResumeButton
@onready var pause_back_button = $PauseOverlay/VBoxContainer/BackToArena
@onready var pause_main_menu_button = $PauseOverlay/VBoxContainer/MainMenu
@onready var pause_exit_button = $PauseOverlay/VBoxContainer/ExitGame

@onready var draw_choice_menu = $DrawChoiceMenu
@onready var color_picker_menu = $ColorChoice

signal human_draw_requested
signal draw_choice_made(should_play: bool)
signal color_selected(color: Card.CardColor)

var name_labels: Array[Label] = []

# En ordbok som översätter spelets färger till riktiga färgkoder!
const UNO_COLORS = {
	Card.CardColor.RED: Color(0.9, 0.2, 0.2), # 230, 51,51
	Card.CardColor.BLUE: Color(0.2, 0.4, 0.9), # 51, 102, 230
	Card.CardColor.GREEN: Color(0.2, 0.8, 0.2), # 51, 204, 51
	Card.CardColor.YELLOW: Color(0.9, 0.8, 0.2), # 230, 204, 51
	Card.CardColor.WILD: Color(1.0, 1.0, 1.0)
}

var last_player_index: int = -1
var _active_draws: int = 0

# --- SPELETS LOGIK ---
var game_manager: GameManager
var player_uis: Array[PlayerHandUI] = []

# Hur många pixlar från skärmens kant händerna ska ligga
@export var edge_margin: float = 100.0 

func _ready():
	await get_tree().process_frame
	
	# Lägg in händerna i en lista så plats 0 = bottom, plats 1 = left, osv.
	player_uis = [bottom_hand, left_hand, top_hand, right_hand]
	name_labels = [bottom_name_label, left_name_label, top_name_label, right_name_label]
	
	_update_layout()
	
	# _test_piles() 
	
	start_real_game()

func _update_layout():
	var screen_size = get_viewport_rect().size
	var center = screen_size / 2.0
	
# --- 1. SÄTT DYNAMISK STORLEK (NYTT OCH SÄKERT!) ---
	# Händerna får max ta upp X% av skärmens längd åt sitt håll. 
	# Då lämnar vi trygga tomrum i alla fyra hörn!
	var horizontal_width = screen_size.x * 0.60 
	var vertical_width = screen_size.y * 0.70 
	
	# Höjden på det nedskalade kortet
	var hand_height = 160.0 
	
	bottom_hand.size = Vector2(horizontal_width, hand_height)
	top_hand.size = Vector2(horizontal_width, hand_height)
	
	# Observera att X här är vertical_width, eftersom vi definierar boxen 
	# INNAN vi roterar den 90 grader!
	left_hand.size = Vector2(vertical_width, hand_height)
	right_hand.size = Vector2(vertical_width, hand_height)

	# --- 2. CENTRERA PIVOT ---
	_set_center_pivot(bottom_hand)
	_set_center_pivot(top_hand)
	_set_center_pivot(left_hand)
	_set_center_pivot(right_hand)

	# --- 3. PLACERA OCH ROTERA ---
	# Botten (Människan)
	bottom_hand.position = Vector2(center.x - bottom_hand.size.x / 2.0, screen_size.y - edge_margin - bottom_hand.size.y / 2.0)
	bottom_hand.rotation_degrees = 0
	
	# Toppen 
	top_hand.position = Vector2(center.x - top_hand.size.x / 2.0, edge_margin - top_hand.size.y / 2.0)
	top_hand.rotation_degrees = 180
	
	# Vänster 
	left_hand.position = Vector2(edge_margin - left_hand.size.x / 2.0, center.y - left_hand.size.y / 2.0)
	left_hand.rotation_degrees = 90
	
	# Höger 
	right_hand.position = Vector2(screen_size.x - edge_margin - right_hand.size.x / 2.0, center.y - right_hand.size.y / 2.0)
	right_hand.rotation_degrees = -90


func _set_center_pivot(control_node: Control):
	# Flyttar nodens "gångjärn" till exakt mitten av dess bredd och höjd
	control_node.pivot_offset = control_node.size / 2.0


# --- BARA FÖR TEST ---
func _test_piles():
	# 1. Bygg Plockhögen (Draw Pile)
	# Vi loopar 108 gånger för att skapa den tjocka leken
	for i in range(108):
		var card = card_ui_scene.instantiate()
		draw_pile_node.add_child(card)
		
		card.set_interactable(false)
		
		# Vänd baksidan uppåt (Eftersom vi inte har anropat set_card_data är kortet 'tomt')
		card.set_face_up(false) 
		
		# Centrera kortet över vår punkt, minus halva dess storlek
		var center_offset = -card.size / 2.0
		
		# Den falska 3D-effekten! Varje kort flyttas 0.3 pixlar snett uppåt vänster
		var depth_offset = Vector2(-i * 0.3, -i * 0.3) 
		
		card.position = center_offset + depth_offset


	# 2. Bygg Kasthögen (Discard Pile)
	# Vi skapar tre låtsaskort för att se stökigheten
	var dummy_discard = [
		Card.new(Card.CardColor.RED, Card.CardValue.FIVE),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.BLUE, Card.CardValue.SKIP),
		Card.new(Card.CardColor.GREEN, Card.CardValue.EIGHT)
	]
	
	for i in range(dummy_discard.size()):
		var card = card_ui_scene.instantiate()
		discard_pile_node.add_child(card)
		
		card.set_interactable(false)
		
		card.set_card_data(dummy_discard[i])
		card.set_face_up(true)
		
		var center_offset = -card.size / 2.0
		
		# Stökigheten! Slumpa fram en liten knuff och rotation
		var randomness_translate = 5
		var randomness_rotate = 7
		var messy_offset = Vector2(randf_range(-randomness_translate, randomness_translate), randf_range(-randomness_translate, randomness_translate))
		card.rotation_degrees = randf_range(-randomness_rotate, randomness_rotate)
		
		card.position = center_offset + messy_offset

func start_real_game():
	var players: Array[Player] = []
	var order = ["bottom", "left", "top", "right"]
	
	# 1. Skapa spelarna dynamiskt baserat på GameSettings
	for i in range(order.size()):
		var pos_name = order[i]
		var cfg = GameSettings.slots[pos_name]
		
		if cfg.active:
			var p: Player
			if cfg.is_human:
				# För människan använder vi namnet från settings (t.ex. "Spelare 1")
				p = Player.new(players.size(), cfg.ai_name, true, null)
			else:
				# 1. Skapa hjärnan baserat på typ
				var brain: AIPlayer = null
				match cfg.ai_type:
					GameSettings.AIType.SIMPLE:
						brain = AISimple.new()
					# Här lägger du till fler typer allt eftersom
					_:
						brain = AISimple.new()
				
				# 2. Hämta namnet direkt från AI-hjärnan!
				var final_name = brain.ai_name if brain.ai_name != "" else cfg.ai_name
				
				p = Player.new(players.size(), final_name, false, brain)
			
			p.set_meta("ui_index", i)
			players.append(p)
	
	# 2. Starta GameManager med de aktiva spelarna
	game_manager = GameManager.new(players)
	add_child(game_manager)
	
	# 3. Inställningar från GameSettings
	game_manager.visual_mode = true
	# Justera hastigheten (t.ex. 1.0 / 2.0 om vi kör dubbel fart)
	game_manager.turn_delay = 1.0 / GameSettings.game_speed
	
	# 4. Koppla alla dina befintliga signaler
	game_manager.card_played.connect(_on_card_played)
	game_manager.card_drawn.connect(_on_card_drawn)
	game_manager.turn_started.connect(_on_turn_started)
	game_manager.game_over.connect(_on_game_ended)
	
	# Game Over & Pause menyer (dina originalkopplingar)
	restart_button.pressed.connect(_on_restart_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	resume_button.pressed.connect(_toggle_pause)
	pause_exit_button.pressed.connect(_on_exit_pressed) 
	pause_main_menu_button.pressed.connect(_on_main_menu_pressed)
	
	# 5. Rita upp startläget
	# Nu har alla i 'players' hunnit få sin 'ui_index' metadata!
	update_all_visuals()
	_spawn_discard_card(game_manager.state.discard_pile[-1])
	
	# Vänta in utdelningen (anpassat efter hastighet)
	await get_tree().create_timer(1.5 / GameSettings.game_speed).timeout
	
	# Hantera labels och spacing för de som är med
	# Först: Göm ALLA labels och UI-händer som default
	for i in range(4):
		name_labels[i].hide()
		# Om du vill dölja tomma händer helt:
		# player_uis[i].hide()

	# Sen: Visa och uppdatera bara de som faktiskt spelar
	for p in players:
		var ui_idx = p.get_meta("ui_index")
		name_labels[ui_idx].text = p.name
		name_labels[ui_idx].show()
		player_uis[ui_idx].show()
		player_uis[ui_idx]._adjust_card_spacing()
	
	# 6. STARTA MATCHEN! 
	game_manager.run_full_game(GameSettings.max_turns)


func update_all_visuals():
	# 1. Synka de fysiska händerna
	for i in range(game_manager.state.players.size()):
		var logical_player = game_manager.state.players[i]
		
		# Hämta UI-indexet som vi sparade i start_real_game
		var ui_idx = logical_player.get_meta("ui_index")
		var hand_ui = player_uis[ui_idx]
		
		# Hämta rätt inställning för visa/dölj kort från GameSettings
		var pos_name = ["bottom", "left", "top", "right"][ui_idx]
		var show_face = GameSettings.slots[pos_name].show_cards
		
		# Uppdatera handen med rätt kort och rätt visningsläge
		hand_ui.update_hand(logical_player.hand, show_face)
		
	# 2. Synka plockhögen i mitten
	_update_draw_pile_visual()
	
	# 3. Kolla om hjärnan precis har blandat om kasthögen!
	if discard_pile_node.get_child_count() > game_manager.state.discard_pile.size():
		_cleanup_discard_pile_visual()


# --- SIGNAL MOTTAGARE ---
func _on_card_drawn(player_index: int, card: Card):
	# 1. Hämta rätt UI-plats via metadata
	var p = game_manager.state.players[player_index]
	var ui_idx = p.get_meta("ui_index")
	var target_hand = player_uis[ui_idx]
	
	# Bestäm om vi ska visa framsidan (baserat på GameSettings)
	var pos_name = ["bottom", "left", "top", "right"][ui_idx]
	var show_face = GameSettings.slots[pos_name].show_cards
	
	# 2. Hantera delay för flera kort (anpassat efter game_speed)
	var base_delay = 0.25 / GameSettings.game_speed
	var delay_time = _active_draws * base_delay
	_active_draws += 1 
	
	_update_draw_pile_visual()
	
	# 3. Skapa det flygande kortet
	var flying_card = card_ui_scene.instantiate()
	add_child(flying_card)
	
	flying_card.z_index = 20 
	flying_card.z_as_relative = false
	flying_card.set_interactable(false)
	
	# Sätt rätt data och visa/dölj baksidan
	flying_card.set_card_data(card)
	flying_card.set_face_up(show_face) 
	
	flying_card.pivot_offset = flying_card.size / 2.0
	
	# Startposition vid talongen
	var start_pos = draw_pile_node.global_position - (flying_card.size / 2.0)
	flying_card.global_position = start_pos
	
	# 4. Beräkna målet (Din magiska fix för runda händer/rotation)
	var target_rot = target_hand.rotation_degrees
	var target_center = target_hand.get_global_transform() * (target_hand.size / 2.0)
	
	var child_count = target_hand.container.get_child_count()
	if child_count > 0:
		var last_card = target_hand.container.get_child(child_count - 1)
		var last_card_center = last_card.get_global_transform() * (last_card.size / 2.0)
		var right_direction = target_hand.get_global_transform().x.normalized()        
		target_center = last_card_center + (right_direction * (flying_card.size.x / 2.0))
		
	var target_pos = target_center - (flying_card.size / 2.0)
	
	# 5. Animera (Anpassat efter game_speed)
	if delay_time > 0:
		flying_card.hide()
		
	var tween = create_tween()
	var anim_time = 0.5 / GameSettings.game_speed
	
	if delay_time > 0:
		tween.tween_interval(delay_time)
		tween.tween_callback(flying_card.show)
	
	# Använd global_position för att vara säker i det roterade utrymmet
	tween.tween_property(flying_card, "global_position", target_pos, anim_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flying_card, "rotation_degrees", target_rot, anim_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	flying_card.queue_free()
	
	_active_draws -= 1
	
	# 6. Slutligen: Uppdatera den riktiga handen
	if _active_draws == 0:
		# Här skickar vi med show_face till update_hand
		target_hand.update_hand(p.hand, show_face)
		update_all_visuals()
		target_hand.play_flex_animation()

func _on_card_played(player_index: int, card: Card, declared_color: Card.CardColor):
	# --- NYTT: Hämta rätt UI-index via metadata ---
	var p = game_manager.state.players[player_index]
	var ui_idx = p.get_meta("ui_index")
	
	# Använd ui_idx istället för player_index för ALLT som rör grafiken
	var hand_ui = player_uis[ui_idx] 
	var start_rotation = hand_ui.rotation_degrees
	
	var children = hand_ui.container.get_children()
	var chosen_ui_card = null
	
	# ... (Samma logik som förut för att hitta chosen_ui_card) ...
	if children.size() > 0:
		for ui_card in children:
			if ui_card.has_meta("logical_card"):
				var logical = ui_card.get_meta("logical_card")
				if logical.color == card.color and logical.value == card.value:
					chosen_ui_card = ui_card
					break
		if chosen_ui_card == null:
			chosen_ui_card = children[randi() % children.size()]

	if chosen_ui_card != null:
		_spawn_discard_card(card, chosen_ui_card, start_rotation)
		
		var card_index = chosen_ui_card.get_index()
		var hole_size = chosen_ui_card.size
		
		chosen_ui_card.hide()
		chosen_ui_card.queue_free()
		
		var dummy_hole = Control.new()
		dummy_hole.custom_minimum_size = hole_size
		hand_ui.container.add_child(dummy_hole)
		hand_ui.container.move_child(dummy_hole, card_index)
		
		# NYTT: Justera timer med GameSettings-hastighet!
		await get_tree().create_timer(0.4 / GameSettings.game_speed).timeout
		
		if is_instance_valid(dummy_hole):
			var current_sep = hand_ui.container.get_theme_constant("separation")
			var target_hole_size = max(0.0, -current_sep)
			
			var tween = create_tween()
			# NYTT: Även tween-hastigheten påverkas
			var tween_time = 0.25 / GameSettings.game_speed
			tween.tween_property(dummy_hole, "custom_minimum_size:x", target_hole_size, tween_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			await tween.finished
			if is_instance_valid(dummy_hole):
				dummy_hole.queue_free()
	else:
		await get_tree().create_timer(0.4 / GameSettings.game_speed).timeout
	
	var final_color = declared_color if card.color == Card.CardColor.WILD else card.color
	update_ui_color(final_color)
	
	# --- NYTT: Skicka med show_cards-inställningen ---
	var pos_name = ["bottom", "left", "top", "right"][ui_idx]
	var show_cards = GameSettings.slots[pos_name].show_cards
	hand_ui.update_hand(p.hand, show_cards)
	
	var cards_left = p.hand.size()
	if cards_left == 1:
		# UNO-animationen behöver också veta vilken UI-plats det gäller
		_show_uno_animation(ui_idx) 
	
	if _active_draws == 0:
		update_all_visuals()


# --- VISUELLA HJÄLPARE ---
func _spawn_discard_card(card_data: Card, source_ui_card: Control = null, start_rot: float = 0.0):
	var visual_card = card_ui_scene.instantiate()
	discard_pile_node.add_child(visual_card)
	
	# 1. Lyft ALLTID upp kortet när det skapas (även första kortet behöver ligga överst initialt)
	visual_card.z_index = 20
	visual_card.z_as_relative = false
	
	visual_card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	visual_card.set_interactable(false)
	visual_card.set_card_data(card_data)
	visual_card.set_face_up(true)
	
	var normal_size = visual_card.size
	var center_offset = -normal_size / 2.0
	var randomness_translate = 5.0
	var randomness_rotate = 7.0
	var messy_offset = Vector2(randf_range(-randomness_translate, randomness_translate), randf_range(-randomness_translate, randomness_translate))
	
	var final_position = center_offset + messy_offset
	var final_rotation = randf_range(-randomness_rotate, randomness_rotate)
	
	if source_ui_card != null:
		# --- ANIMERAT KORT (Från handen) ---
		visual_card.size = source_ui_card.size
		visual_card.pivot_offset = visual_card.size / 2.0
		var exact_center = source_ui_card.get_global_transform() * (source_ui_card.size / 2.0)
		visual_card.global_position = exact_center - visual_card.pivot_offset
		visual_card.rotation_degrees = start_rot
		
		var tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(visual_card, "position", final_position, 0.4)
		tween.tween_property(visual_card, "rotation_degrees", final_rotation, 0.4)
		tween.tween_property(visual_card, "size", normal_size, 0.4)
		tween.tween_property(visual_card, "pivot_offset", normal_size / 2.0, 0.4)
		
		# När animationen är klar - tvinga ner det i trädet
		tween.finished.connect(func(): _finalize_card_landing(visual_card, final_position))
	else:
		# --- STATISKT KORT (Första kortet vid start) ---
		visual_card.pivot_offset = normal_size / 2.0
		visual_card.position = final_position
		visual_card.rotation_degrees = final_rotation
		# Även här måste vi "landa" kortet logiskt så det tappar sin Z-index fusk
		_finalize_card_landing(visual_card, final_position)

# Ny hjälpfunktion för att garantera ordningen
func _finalize_card_landing(card_node: Control, final_pos: Vector2):
	if is_instance_valid(card_node):
		card_node.z_index = 0
		card_node.z_as_relative = true
		
		# Tvinga kortet att bli sista barnet (ritat överst)
		var pile = card_node.get_parent()
		pile.move_child(card_node, pile.get_child_count() - 1)
		
		# Säkerställ positionen
		card_node.position = final_pos

func _update_draw_pile_visual():
	# 1. Rensa bort den gamla grafiska högen
	for child in draw_pile_node.get_children():
		child.queue_free()
		
	# 2. Kolla hur många kort hjärnan faktiskt har i plockhögen just nu
	var cards_left = game_manager.state.draw_pile.cards.size()
	
	# 3. Bygg upp högen på nytt!
	for i in range(cards_left):
		var visual_card = card_ui_scene.instantiate()
		draw_pile_node.add_child(visual_card)
		
		visual_card.set_interactable(false)
		visual_card.set_face_up(false) 
		
		var center_offset = -visual_card.size / 2.0
		# Tätare mellanrum (0.2) så en lek med 80 kort inte blir onaturligt hög
		var depth_offset = Vector2(-i * 0.2, -i * 0.2) 
		
		visual_card.position = center_offset + depth_offset

func _cleanup_discard_pile_visual():
	# 1. Radera alla grafiska kort i den stökiga högen
	for child in discard_pile_node.get_children():
		child.queue_free()
		
	# 2. Lägg tillbaka det enda kortet som hjärnan sparade
	if game_manager.state.discard_pile.size() > 0:
		var top_card = game_manager.state.discard_pile[-1]
		_spawn_discard_card(top_card)

func _on_turn_started(current_player_index: int):
	var current_color = game_manager.state.current_color
	var direction = game_manager.state.play_direction
	var num_players = game_manager.state.players.size()
	
	# --- NYTT: Mappa om logiska index till UI-index ---
	var current_p = game_manager.state.players[current_player_index]
	var current_ui_idx = current_p.get_meta("ui_index")
	
	# Vi behöver också veta var den FÖRRA spelaren fanns i UI:t
	var last_ui_idx = -1
	if last_player_index != -1:
		last_ui_idx = game_manager.state.players[last_player_index].get_meta("ui_index")
	
	# 1. Tänd den aktiva spelaren, släck de andra (använd i som UI-index)
	for i in range(player_uis.size()):
		player_uis[i].set_active(i == current_ui_idx)
		
	# 2. Om det är allra första draget
	if last_player_index == -1:
		last_player_index = current_player_index
		turn_arrow.hide()
		return
		
	turn_arrow.show()
	
	# 3. Kalkylera om någon blev överhoppad
	var expected_next = (last_player_index + direction + num_players) % num_players
	if expected_next != current_player_index:
		var skip_p = game_manager.state.players[expected_next]
		var skip_ui_idx = skip_p.get_meta("ui_index")
		player_uis[skip_ui_idx].show_skip_animation(UNO_COLORS[current_color])
		
	# 4. Flytta och rotera pilen (Använd UI-indexen här!)
	var start_anchor_name = "AnchorCW" if direction == 1 else "AnchorCCW"
	var target_anchor_name = "AnchorCCW" if direction == 1 else "AnchorCW"
	
	# Hämta noder baserat på de FYSISKA platserna
	var start_node = player_uis[last_ui_idx].get_node(start_anchor_name)
	var target_node = player_uis[current_ui_idx].get_node(target_anchor_name)
	
	turn_arrow.global_position = start_node.global_position
	turn_arrow.look_at(target_node.global_position)
	
	# Färga pilen
	turn_arrow.modulate = UNO_COLORS[current_color]
	
	# Spara vem som fick turen till nästa gång
	last_player_index = current_player_index

func update_ui_color(new_color: Card.CardColor):
	var color_value: Color
	match new_color:
		Card.CardColor.RED: color_value = Color.RED
		Card.CardColor.BLUE: color_value = Color.BLUE
		Card.CardColor.GREEN: color_value = Color.GREEN
		Card.CardColor.YELLOW: color_value = Color.YELLOW
		_: color_value = Color.WHITE # Wild/Vit
		
	# Byt ut 'CurrentColorArrow' mot namnet på din pil-nod i trädet!
	# Om den ligger direkt i VisualMatch skriver du bara $PilenEllerVadDenHeter
	$TurnArrow.self_modulate = color_value

func _show_uno_animation(player_index: int):
	# 1. Skapa en ny textnod i farten
	var uno_label = Label.new()
	uno_label.text = "UNO!"
	
	# 2. Skapa snygga textinställningar (Guldgul med svart kant)
	var settings = LabelSettings.new()
	
	# --- NYTT: Ladda din UNO-font! ---
	# Högerklicka på din font-fil i FileSystem och välj "Copy Path", klistra in här:
	var uno_font = load("res://ui/fonts/Helvetica Bold.ttf") 
	settings.font = uno_font
	
	settings.font_size = 64
	settings.font_color = Color(1.0, 0.898, 0.686, 1.0) # Guld/Gul
	settings.outline_color = Color(0, 0, 0, 1)
	settings.outline_size = 8
	uno_label.label_settings = settings
	
	add_child(uno_label)
	
	# 3. Räkna ut startpositionen (vid spelarens namnskylt är en bra plats!)
	var start_pos = name_labels[player_index].global_position
	uno_label.global_position = start_pos
	
	# 4. Räkna ut riktningen in mot skärmens mitt
	var target_pos = start_pos
	
	# Vi flyttar texten 150 pixlar rakt in mot bordet istället för diagonalt
	match player_index:
		0: # Botten
			target_pos += Vector2(150, 50) # Rakt upp
		1: # Vänster
			target_pos += Vector2(-100, 250)  # Rakt åt höger
		2: # Toppen
			target_pos += Vector2(150, 70)  # Rakt ner
		3: # Höger
			target_pos += Vector2(-50, -250) # Rakt åt vänster

	# (Valfritt) Om du vill att ALLA texter ska "lätta" lite uppåt i luften 
	# precis på slutet, kan vi lägga till en liten knuff här:
	target_pos += Vector2(0, -20)
		
	# 5. Sätt startvärden för animationen (liten och genomskinlig)
	uno_label.scale = Vector2(0.1, 0.1)
	uno_label.modulate.a = 0.0
	
	# Eftersom pivot_offset normalt är i övre vänstra hörnet på kod-skapade Labels,
	# sätter vi den i mitten så att den växer ("scale") snyggt inifrån och ut.
	uno_label.pivot_offset = Vector2(60, 30) # Ungefärlig mittpunkt för texten
	
	# 6. Animera! (Använder parallel för att göra flera saker samtidigt)
	var tween = create_tween().set_parallel(true)
	
	# Flyg inåt med en svag "studs" (EASE_OUT + TRANS_BACK)
	tween.tween_property(uno_label, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Sväll upp till full storlek
	tween.tween_property(uno_label, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Tona in
	tween.tween_property(uno_label, "modulate:a", 1.0, 0.2)
	
	# 7. Efter att den flugit in, tona bort den långsamt och ta bort den
	var fade_tween = create_tween()
	fade_tween.tween_interval(1.5) # Vänta 1.5 sekunder
	fade_tween.tween_property(uno_label, "modulate:a", 0.0, 0.5) # Tona ut på 0.5s
	fade_tween.tween_callback(uno_label.queue_free) # Städa bort!

# En variabel för att hålla koll på om det är din tur att klicka
var human_can_play: bool = false
signal human_card_selected(card_data: Card)

func _on_card_ui_clicked(card_node: Control):
	#print("DEBUG: Klickade på ett kort. human_can_play är: ", human_can_play)
	if not human_can_play:
		print("Inte din tur än!")
		return
		
	if card_node.has_meta("logical_card"):
		var clicked_card = card_node.get_meta("logical_card")
		var top_card = game_manager.state.discard_pile[-1]
		var current_color = game_manager.state.current_color
		
		if clicked_card.is_playable_on(top_card, current_color):
			# Lås dörren direkt så man inte kan dubbelklicka
			human_can_play = false 
			human_card_selected.emit(clicked_card)
		else:
			print("Ogiltigt drag!")

func _on_draw_pile_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("DEBUG: Klickade på plockhögen. human_can_play är: ", human_can_play)
		if human_can_play:
			human_can_play = false
			human_draw_requested.emit()

func _on_game_ended(winner_index: int):
	var winner_name = game_manager.state.players[winner_index].name
	var position_list = [" (Bottom)", " (Left)", " (Top)", " (Right)"]
	winner_label.text = "The Winner is:\n" + winner_name + position_list[winner_index] 
	
	# En snygg inflygning/intoning av skärmen
	game_over_overlay.modulate.a = 0.0
	game_over_overlay.show()
	
	var tween = create_tween()
	tween.tween_property(game_over_overlay, "modulate:a", 1.0, 0.5)

func _on_restart_pressed():
	# Godots absolut bästa funktion för snabba omstarter!
	# Detta laddar om hela scenen från noll, blandar om leken och nollställer AI:n.
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed():
	# Säger åt hela Godot-motorn att stänga ner fönstret och avsluta spelet
	get_tree().quit()

func _toggle_pause():
	if game_over_overlay.visible:
		return

	# Vänd på steken! Är det pausat, spela. Spelar det, pausa.
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	
	# Visa eller dölj menyn
	if new_pause_state:
		pause_overlay.show()
	else:
		pause_overlay.hide()

func _on_main_menu_pressed():
	# VIKTIGT: Släpp pausen innan vi byter scen!
	get_tree().paused = false 
	
	# Just nu har vi ingen Main Menu-scen, så vi printar bara. 
	# När du har byggt en, tar du bort #-tecknet på raden under!
	print("Laddar Main Menu... (Behöver en scen!)")
	# get_tree().change_scene_to_file("res://din_main_menu_scen.tscn")

func show_draw_choice(_card: Card):
	# Visa knappar
	draw_choice_menu.show()
	# Här kan du också uppdatera texten på knapparna om du vill
	
func _on_play_button_pressed():
	draw_choice_menu.hide()
	draw_choice_made.emit(true)

func _on_keep_button_pressed():
	draw_choice_menu.hide()
	draw_choice_made.emit(false)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_U:
			for i in range(4):
				pass
				#_show_uno_animation(i)

func show_color_picker():
	color_picker_menu.show()
	# Här väntar vi på att spelaren klickar på en av färgknapparna
	var selected_color = await color_selected
	color_picker_menu.hide()
	return selected_color

func _on_red_button_pressed():
	color_selected.emit(Card.CardColor.RED)

func _on_blue_button_pressed():
	color_selected.emit(Card.CardColor.BLUE)

func _on_green_button_pressed():
	color_selected.emit(Card.CardColor.GREEN)

func _on_yellow_button_pressed():
	color_selected.emit(Card.CardColor.YELLOW)
