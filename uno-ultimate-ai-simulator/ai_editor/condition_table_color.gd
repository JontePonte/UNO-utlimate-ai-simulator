extends GraphNode

@onready var dropdown = $OptionDropdown

func _ready():
	dropdown.clear()
	
	dropdown.add_item("Most numerous in hand")      # Index 0
	dropdown.add_item("2nd most numerous in hand")  # Index 1
	dropdown.add_item("3rd most numerous in hand")  # Index 2
	dropdown.add_item("Least numerous in hand")     # Index 3
	
	# Sätt portarna (Röd Condition: Vänster IN Vit. Höger UT Grön/Röd)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)
