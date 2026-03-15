extends GraphNode

@onready var dropdown = $OptionButton

func _ready():
	# Fyll dropdown med våra nya val för Test & Aggressive AI
	dropdown.add_item("Can play any card")
	dropdown.add_item("Has playable special card")
	dropdown.add_item("Can play same color")
	dropdown.add_item("Can play same number")
	dropdown.add_item("Has UNO")
	
	# Sätt upp portarna (Rad 0 = Vit In / Grön Ut. Rad 1 = Röd Ut)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)
