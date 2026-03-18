extends GraphNode

@onready var action_dropdown = $OptionDropdown # (eller vad den nu heter hos dig!)
@onready var color_dropdown = $ColorDropdown

func _ready():
	action_dropdown.clear()
	color_dropdown.clear()
	
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
	
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	
	action_dropdown.item_selected.connect(_on_action_selected)
	_on_action_selected(action_dropdown.selected)

func _on_action_selected(index: int):
	# Index 2 (Wild) och Index 3 (+4) behöver båda ett färgval!
	if index == 2 or index == 3:
		color_dropdown.show()
	else:
		color_dropdown.hide()
		
	size.y = 0
