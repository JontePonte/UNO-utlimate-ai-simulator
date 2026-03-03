class_name CardUI
extends Control

# Hämta referenser till dina noder
@onready var inner_color_panel = $Base/InnerColor
@onready var center_text = $Base/InnerColor/CenterText
@onready var top_left_text = $Base/InnerColor/TopLeftText
@onready var bottom_right_text = $Base/InnerColor/BottomRightText

# Denna funktion kallas för att uppdatera kortets utseende
func set_card_data(card: Card):
	if card == null:
		return
		
	# 1. Sätt texten
	var display_text = get_value_string(card.value)
	center_text.text = display_text
	top_left_text.text = display_text
	bottom_right_text.text = display_text
	
	# 2. Ändra färg på kortet
	# Vi duplicerar styleboxen för att inte råka ändra färg på ALLA kort samtidigt!
	var stylebox = inner_color_panel.get_theme_stylebox("panel").duplicate()
	
	match card.color:
		Card.CardColor.RED:
			stylebox.bg_color = Color(0.85, 0.15, 0.15) # Röd
		Card.CardColor.BLUE:
			stylebox.bg_color = Color(0.15, 0.35, 0.85) # Blå
		Card.CardColor.GREEN:
			stylebox.bg_color = Color(0.20, 0.65, 0.25) # Grön
		Card.CardColor.YELLOW:
			stylebox.bg_color = Color(0.95, 0.80, 0.10) # Gul
		Card.CardColor.WILD:
			stylebox.bg_color = Color(0.15, 0.15, 0.15) # Mörkgrå för Wild-kort
			
	# Applicera den nya färgen på panelen
	inner_color_panel.add_theme_stylebox_override("panel", stylebox)

# Hjälpfunktion för att översätta valör till text
func get_value_string(val: Card.CardValue) -> String:
	match val:
		Card.CardValue.ZERO: return "0"
		Card.CardValue.ONE: return "1"
		Card.CardValue.TWO: return "2"
		Card.CardValue.THREE: return "3"
		Card.CardValue.FOUR: return "4"
		Card.CardValue.FIVE: return "5"
		Card.CardValue.SIX: return "6_" # Understreck för att skilja från 9
		Card.CardValue.SEVEN: return "7"
		Card.CardValue.EIGHT: return "8"
		Card.CardValue.NINE: return "9_" # Understreck för att skilja från 6
		Card.CardValue.SKIP: return "Ø" # Tillfällig symbol för Skip
		Card.CardValue.REVERSE: return "⇄" # Tillfällig symbol för Reverse
		Card.CardValue.DRAW_TWO: return "+2"
		Card.CardValue.WILD: return "W"
		Card.CardValue.WILD_DRAW_FOUR: return "+4"
		_: return ""
