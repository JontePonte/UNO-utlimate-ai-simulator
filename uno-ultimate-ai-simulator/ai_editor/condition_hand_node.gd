extends GraphNode

func _ready():
	var dropdown = $OptionDropdown
	dropdown.clear()
	
	# --- BEHÅLL GAMLA INDEX (0-4) ---
	dropdown.add_item("Can play any card")            # Index 0
	dropdown.add_item("Has any playable special card")# Index 1
	dropdown.add_item("Has any playable attack card") # Index 2
	dropdown.add_item("Can play same color")          # Index 3
	dropdown.add_item("Can play same number")         # Index 4
	dropdown.add_item("Has UNO")                      # Index 5
	
	# --- LÄGG TILL DE NYA (5-9) ---
	dropdown.add_item("Can play Wild Card")           # Index 6
	dropdown.add_item("Can play +4 Wild Card")        # Index 7
	dropdown.add_item("Can play +2 Card")             # Index 8
	dropdown.add_item("Can play Skip Card")           # Index 9
	dropdown.add_item("Can play Reverse Card")        # Index 10
	
	# Sätt upp portarna (Rad 0 = Vit In / Grön Ut. Rad 1 = Röd Ut)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)
