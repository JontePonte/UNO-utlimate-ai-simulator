extends GraphNode

@onready var dropdown = $OptionButton

func _ready():
	# 1. Fyll dropdown-menyn med lite smarta abstrakta val!
	dropdown.add_item("Can play same color")
	dropdown.add_item("Can play same number")
	dropdown.add_item("Has UNO")
	dropdown.add_item("Must draw card")
	
	# 2. Sätt upp portarna (pluttarna)!
	# set_slot(rad_index, vänster_aktiv, typ, färg, höger_aktiv, typ, färg)
	
	# Rad 0 (Dropdown-menyn): Ingång (Vit) och True-utgång (Grön)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	
	# Rad 1 (False-labeln): Ingen ingång, False-utgång (Röd)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)
