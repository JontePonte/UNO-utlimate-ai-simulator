extends GraphNode

@onready var opponent_dropdown = $OpponentDropdown
@onready var option_dropdown = $OptionDropdown

func _ready():
	opponent_dropdown.clear()
	option_dropdown.clear()
	
	opponent_dropdown.add_item("Next Player")      			# Index 0
	opponent_dropdown.add_item("Previous Player")			# Index 1
	opponent_dropdown.add_item("Any Player")				# Index 2
	opponent_dropdown.add_item("Player with most cards")	# Index 3
	opponent_dropdown.add_item("Player with least cards")	# Index 4

	option_dropdown.add_item("has less cards than me")     # Index 0
	option_dropdown.add_item("has more cards than me")     # Index 1
	option_dropdown.add_item("has equal amount of cards")  # Index 2
	option_dropdown.add_item("has one or two cards")       # Index 3
	option_dropdown.add_item("has just one card UNO")      # Index 4
	
	# Sätt portarna (Röd Condition: Vänster IN Vit. Höger UT Grön/Röd)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.RED)
