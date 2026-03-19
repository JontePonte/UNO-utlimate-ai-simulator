extends GraphNode

@onready var dropdown = $OptionDropdown

func _ready():
	dropdown.clear()
	
	dropdown.add_item("Only One")  # Index 0
	dropdown.add_item("Multiple")  # Index 1
	dropdown.add_item("None")  # Index 2
	
	# Sätt portarna (Röd Condition: Vänster IN Vit. Höger UT Grön/Röd)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)
