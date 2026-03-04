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


func _ready() -> void:
	var test_card = Card.new(Card.CardColor.GREEN, Card.CardValue.REVERSE)
	set_card_data(test_card)

# Denna funktion kallas för att uppdatera kortets utseende
func set_card_data(card: Card):
	if card == null:
		return
		
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
	var is_plus_card = (card.value == Card.CardValue.DRAW_TWO or card.value == Card.CardValue.WILD_DRAW_FOUR)
	var is_wild_card = card.value == Card.CardValue.WILD
	var is_reverse_card = card.value == Card.CardValue.REVERSE
	
	# Byt ut dessa mot de värden du använder i din UI-editor!
	var center_normal_size = 150
	var center_small_size = 130
	var center_reverse_size = 140
	
	var corner_normal_size = 60
	var corner_wild_size = 55
	var corner_small_size = 50
	
	if is_plus_card:
		center_text.label_settings.font_size = center_small_size
		top_left_text.label_settings.font_size = corner_small_size
		bottom_right_text.label_settings.font_size = corner_small_size
	elif is_wild_card:
		top_left_text.label_settings.font_size = corner_wild_size 
		bottom_right_text.label_settings.font_size = corner_wild_size
	elif is_reverse_card:
		center_text.label_settings.font_size = center_reverse_size
		center_text.rotation_degrees = -50
		center_text.position = Vector2(0,40)
		top_left_text.label_settings.font_size = corner_small_size
		top_left_text.rotation_degrees = -50
		top_left_text.position = Vector2(-20,20)
		bottom_right_text.label_settings.font_size = corner_small_size
		bottom_right_text.rotation_degrees = -50
		bottom_right_text.position = Vector2(110, 240)
	else:
		center_text.label_settings.font_size = center_normal_size
		top_left_text.label_settings.font_size = corner_normal_size
		bottom_right_text.label_settings.font_size = corner_normal_size
	
	
	# 1.8 Hantera Wild-kortens utseende
	var is_wild = (card.color == Card.CardColor.WILD)
	wild_icon.visible = is_wild
	
	# Om det är ett rent Wild-kort döljer vi centertexten (vi vill bara se färg-ovalen)
	# Men är det ett +4-kort så vill vi att "+4" ska stå kvar ovanpå ovalen!
	if is_wild and card.value == Card.CardValue.WILD:
		center_text.visible = false
	else:
		center_text.visible = true
	
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
		Card.CardValue.SKIP: return "Ø"
		Card.CardValue.REVERSE: return "⇄"
		Card.CardValue.DRAW_TWO: return "+2"
		Card.CardValue.WILD: return "W"
		Card.CardValue.WILD_DRAW_FOUR: return "+4"
		_: return ""
