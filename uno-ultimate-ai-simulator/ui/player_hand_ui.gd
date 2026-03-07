class_name PlayerHandUI
extends Control

@export var card_ui_scene: PackedScene 
@onready var container = $HBoxContainer
@onready var skip_symbol = $SkipSymbol

# Hur mycket överlappning vi vill ha som standard (byt till det du gillar)
var default_separation: float = -60.0 

func _ready() -> void:
	resized.connect(_adjust_card_spacing)
	#test_hand()
	if skip_symbol:
		skip_symbol.hide()

func update_hand(hand_cards: Array):
	# 1. Rensa bort alla gamla visuella kort först
	for child in container.get_children():
		child.queue_free()
		
	# 2. Skapa ett nytt CardUI för varje logiskt kort i handen
	for card in hand_cards:
		var visual_card = card_ui_scene.instantiate()
		container.add_child(visual_card)
		
		visual_card.set_card_data(card)
		visual_card.set_face_up(true) 
		
	# 3. Kalla på vår nya beräkning, men vänta en "frame" så Godot 
	# hinner rita upp korten och vi vet deras faktiska bredd!
	call_deferred("_adjust_card_spacing")


func _adjust_card_spacing():
	var card_count = container.get_child_count()
	
	# Är handen tom eller har 1 kort behöver vi inte räkna separation
	if card_count <= 1:
		container.add_theme_constant_override("separation", default_separation)
		return
		
	# Ta reda på hur mycket plats vi HAR, och hur breda korten ÄR
	var max_width = self.size.x # Bredd på hela UI-containern
	var card_width = container.get_child(0).size.x # Bredden på ETT kort
	
	# Om vi lägger korten kant i kant, hur breda är de totalt?
	var total_cards_width = card_count * card_width
	
	# Hur mycket utrymme har vi över (eller saknar) för mellanrummen?
	var space_for_separation = max_width - total_cards_width
	
	# Räkna ut vad separationen BEHÖVER vara för att få plats
	# (Delat på card_count - 1 eftersom 5 kort har 4 mellanrum)
	var needed_separation = space_for_separation / (card_count - 1)
	
	# Vi vill inte att de dras ISÄR mer än standardvärdet, men vi 
	# tillåter att de trycks IHOP hur mycket som helst.
	var final_separation = min(default_separation, needed_separation)
	
	# Tryck in det nya värdet i HBoxContainern!
	container.add_theme_constant_override("separation", final_separation)


# --- BARA FÖR TEST ---
func test_hand():
	var dummy_hand = []
	# Kasta in 15 kort för att se magin jobba!
	for i in range(50):
		dummy_hand.append(Card.new(Card.CardColor.RED, Card.CardValue.SIX))
	
	update_hand(dummy_hand)
	
func set_active(is_active: bool):
	# Mjuka upp färgbytet med en Tween!
	var tween = create_tween()
	if is_active:
		tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	else:
		# Gör de inaktiva spelarna lite mörkare
		tween.tween_property(self, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.3)

func show_skip_animation(active_color: Color):
	skip_symbol.modulate = active_color
	skip_symbol.show()
	
	# En snygg animation som tonar bort symbolen efter 1.5 sekunder
	var tween = create_tween()
	tween.tween_property(skip_symbol, "modulate:a", 0.0, 1.0).set_delay(1.5)
	tween.tween_callback(skip_symbol.hide)
	tween.tween_callback(func(): skip_symbol.modulate.a = 1.0) # Återställ alpha för nästa gång
