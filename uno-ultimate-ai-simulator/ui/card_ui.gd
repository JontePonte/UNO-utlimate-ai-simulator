class_name CardUI
extends Control

# Hämta referenser till dina noder
@onready var inner_color_panel = $Base/InnerColor
@onready var center_text = $Base/InnerColor/CenterText
@onready var top_left_text = $Base/InnerColor/TopLeftText
@onready var bottom_right_text = $Base/InnerColor/BottomRightText

@onready var center_underline = $Base/InnerColor/CenterText/UnderLineC
@onready var top_left_underline = $Base/InnerColor/TopLeftText/UnderLineL
@onready var bottom_right_underline = $Base/InnerColor/BottomRightText/UnderLineR

@onready var wild_icon = $Base/InnerColor/WildIcon

@onready var center_skip = $Base/InnerColor/CenterStkip
@onready var left_skip = $Base/InnerColor/LeftCornerSkip
@onready var right_skip = $Base/InnerColor/RightCornerSkip

@onready var card_back = $CardBack

@onready var base_node = $Base
var base_start_y: float = 0.0

signal card_clicked(card: Card)
var my_card: Card

func _ready() -> void:
	# Spara var Base-noden ligger från början (oftast 0)
	base_start_y = base_node.position.y
	
	# Koppla mus-händelserna till funktioner via kod
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	
	gui_input.connect(_on_gui_input)

# Denna funktion kallas för att uppdatera kortets utseende
func set_card_data(card: Card):
	if card == null:
		return
	my_card = card
	
	# 1. Sätt texten
	var display_text = get_value_string(card.value)
	center_text.text = display_text
	top_left_text.text = display_text
	bottom_right_text.text = display_text
	
	# 1.5 Slå på understrykning BARA för 6 och 9
	var needs_underline = (card.value == Card.CardValue.SIX or card.value == Card.CardValue.NINE)
	center_underline.visible = needs_underline
	top_left_underline.visible = needs_underline
	bottom_right_underline.visible = needs_underline
	
	# 1.6 Ändra textstorlek för specialkort (+2 och +4)
	var is_plus_two_card = card.value == Card.CardValue.DRAW_TWO
	var is_wild_card = card.value == Card.CardValue.WILD
	var is_wild_four_card = card.value == Card.CardValue.WILD_DRAW_FOUR
	var is_reverse_card = card.value == Card.CardValue.REVERSE
	
	# Byt ut dessa mot de värden du använder i din UI-editor!
	var center_normal_size = 120
	var center_small_size = 105
	var center_reverse_size = 110
	
	var corner_normal_size = 48
	var corner_wild_size = 45
	var corner_small_size = 40
	
	if is_plus_two_card:
		center_text.label_settings.font_size = center_small_size
		top_left_text.label_settings.font_size = corner_small_size
		bottom_right_text.label_settings.font_size = corner_small_size
	elif is_wild_card:
		top_left_text.label_settings.font_size = corner_wild_size 
		bottom_right_text.label_settings.font_size = corner_wild_size
		wild_icon.visible = true
		center_text.visible = false
	elif is_wild_four_card:
		center_text.label_settings.font_size = center_small_size
		top_left_text.label_settings.font_size = corner_small_size
		bottom_right_text.label_settings.font_size = corner_small_size
		wild_icon.visible = true
	elif is_reverse_card:
		center_text.label_settings.font_size = center_reverse_size
		center_text.rotation_degrees = -50
		center_text.position = Vector2(0,40)
		top_left_text.label_settings.font_size = corner_small_size
		top_left_text.rotation_degrees = -50
		top_left_text.position = Vector2(-20,20)
		bottom_right_text.label_settings.font_size = corner_small_size
		bottom_right_text.rotation_degrees = -50
		bottom_right_text.position = Vector2(80, 192)
	else:
		center_text.label_settings.font_size = center_normal_size
		top_left_text.label_settings.font_size = corner_normal_size
		bottom_right_text.label_settings.font_size = corner_normal_size
	
	# 1.81 Handle Skip-card visability
	var is_skip = (card.value == Card.CardValue.SKIP)
	if is_skip:
		center_skip.visible = true
		left_skip.visible = true
		right_skip.visible = true
		
		center_text.visible = false
		top_left_text.visible = false
		bottom_right_text.visible = false
		
	# 2. Ändra färg på kortet
	var new_color = Color.WHITE
	match card.color:
		Card.CardColor.RED: new_color = Color(0.85, 0.15, 0.15)
		Card.CardColor.BLUE: new_color = Color(0.15, 0.35, 0.85)
		Card.CardColor.GREEN: new_color = Color(0.20, 0.65, 0.25)
		Card.CardColor.YELLOW: new_color = Color(0.95, 0.80, 0.10)
		Card.CardColor.WILD: new_color = Color(0.15, 0.15, 0.15)

	# Skapa en helt ny StyleBox
	var new_stylebox = StyleBoxFlat.new()
	new_stylebox.bg_color = new_color
	
	# Sätt hörnradien (du nämnde att du använde 20px)
	var InnerColor_corner_radius = 10
	new_stylebox.corner_radius_top_left = InnerColor_corner_radius
	new_stylebox.corner_radius_top_right = InnerColor_corner_radius
	new_stylebox.corner_radius_bottom_left = InnerColor_corner_radius
	new_stylebox.corner_radius_bottom_right = InnerColor_corner_radius
	
	var border_thickness = 0 
	new_stylebox.border_width_left = border_thickness
	new_stylebox.border_width_top = border_thickness
	new_stylebox.border_width_right = border_thickness
	new_stylebox.border_width_bottom = border_thickness
	
	# Sätt kanten till helt genomskinlig
	new_stylebox.border_color = Color(0, 0, 0, 0) 

	# Applicera den nya boxen på panelen
	inner_color_panel.add_theme_stylebox_override("panel", new_stylebox)

# Hjälpfunktion för att översätta valör till text
func get_value_string(val: Card.CardValue) -> String:
	match val:
		Card.CardValue.ZERO: return "0"
		Card.CardValue.ONE: return "1"
		Card.CardValue.TWO: return "2"
		Card.CardValue.THREE: return "3"
		Card.CardValue.FOUR: return "4"
		Card.CardValue.FIVE: return "5"
		Card.CardValue.SIX: return "6"
		Card.CardValue.SEVEN: return "7"
		Card.CardValue.EIGHT: return "8"
		Card.CardValue.NINE: return "9"
		Card.CardValue.SKIP: return ""
		Card.CardValue.REVERSE: return "⇄"
		Card.CardValue.DRAW_TWO: return "+2"
		Card.CardValue.WILD: return "W"
		Card.CardValue.WILD_DRAW_FOUR: return "+4"
		_: return ""

# Använd denna för att vända på kortet
func set_face_up(is_face_up: bool):
	card_back.visible = !is_face_up

func _on_hover_enter():
	# 1. Tvinga detta kort att ritas OVANPÅ alla andra i handen
	z_index = 10 
	
	# 2. Skapa en mjuk animation (Tween) som flyttar Base-noden uppåt (-40 pixlar)
	var tween = create_tween()
	# Sätt animationen till att ta 0.1 sekunder för en snabb, snärtig känsla
	tween.tween_property(base_node, "position:y", base_start_y - 40, 0.1)

func _on_hover_exit():
	# 1. Återställ Z-index så det smälter in i handen igen
	z_index = 0
	
	# 2. Animera tillbaka Base-noden till sin startposition
	var tween = create_tween()
	tween.tween_property(base_node, "position:y", base_start_y, 0.1)

func _on_gui_input(event: InputEvent):
	# Om händelsen är ett musklick, det är vänster knapp, och den trycks NER (inte släpps)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		card_clicked.emit(my_card) # Skrik ut till världen vilket kort som klickades!
