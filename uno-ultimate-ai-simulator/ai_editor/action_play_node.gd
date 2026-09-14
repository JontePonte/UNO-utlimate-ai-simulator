extends GraphNode

@onready var action_dropdown = $OptionDropdown
@onready var color_dropdown = $ColorDropdown
@onready var same_number_dropdown = $SameNumberDropdown

func _ready():
	action_dropdown.clear()
	color_dropdown.clear()
	same_number_dropdown.clear() # <-- Glöm inte att rensa denna också!
	
	# --- DROPDOWN 1: Vilken handling? ---
	action_dropdown.add_item("Play first valid card")             # Index 0
	action_dropdown.add_item("Play first special card")           # Index 1
	action_dropdown.add_item("Play first attack card")            # Index 2
	action_dropdown.add_item("Play Wild Card")                    # Index 3
	action_dropdown.add_item("Play +4 Wild Card")                 # Index 4
	action_dropdown.add_item("Play +2 Card")                      # Index 5
	action_dropdown.add_item("Play Skip Card")                    # Index 6
	action_dropdown.add_item("Play Reverse Card")                 # Index 7
	action_dropdown.add_item("Play Same Color Card")              # Index 8
	action_dropdown.add_item("Play Same Number Card")             # Index 9
	
	# --- DROPDOWN 2: Vilken färg? (Syns bara för Wild) ---
	color_dropdown.add_item("Set Color: Most numerous")           # Index 0
	color_dropdown.add_item("Set Color: 2nd most numerous")       # Index 1
	color_dropdown.add_item("Set Color: 3rd most numerous")       # Index 2
	color_dropdown.add_item("Set Color: Least numerous")          # Index 3
	
	# --- DROPDOWN 3: Strategi för Samma Nummer ---
	same_number_dropdown.add_item("Prioritize Current Color")     # Index 0
	same_number_dropdown.add_item("Prioritize Most Common Color") # Index 1
	same_number_dropdown.add_item("Prioritize Color Change")      # Index 2
	
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	
	action_dropdown.item_selected.connect(_on_action_selected)
	_on_action_selected(action_dropdown.selected)

func _on_action_selected(index: int):
	# Bara Index 3 (Wild) och 4 (+4) ska visa färgvalet
	if index == 3 or index == 4:
		color_dropdown.show()
		same_number_dropdown.hide()
	# 9 = Play Same Number Card
	elif index == 9:
		color_dropdown.hide()
		same_number_dropdown.show()
	# Alla andra val
	else:
		color_dropdown.hide()
		same_number_dropdown.hide()
		
	size.y = 0
