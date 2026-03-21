extends GraphNode
# Title: "Condition: Last Move Was"

@onready var player_dropdown = $HBoxContainer/PlayerDropdown
@onready var action_dropdown = $ActionDropdown

func _ready() -> void:
	player_dropdown.clear()
	action_dropdown.clear()
	
	player_dropdown.add_item("My")      				# Index 0	
	player_dropdown.add_item("Next Player")      		# Index 1
	player_dropdown.add_item("Previous Player")			# Index 2
	player_dropdown.add_item("Any Player")				# Index 3

	action_dropdown.add_item("Play special card")           # Index 0
	action_dropdown.add_item("Play attack card")            # Index 1
	action_dropdown.add_item("Play Wild Card")              # Index 2
	action_dropdown.add_item("Play +4 Wild Card")           # Index 3
	action_dropdown.add_item("Play +2 Card")                # Index 4
	action_dropdown.add_item("Play Skip Card")              # Index 5
	action_dropdown.add_item("Play Reverse Card")           # Index 6
	action_dropdown.add_item("Play Same Color Card")        # Index 7
	action_dropdown.add_item("Play Same Number Card")       # Index 8
	action_dropdown.add_item("Draw Card")                   # Index 9
	
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.RED)

func get_data() -> Dictionary:
	return {
		"player_target": player_dropdown.selected,
		"action_target": action_dropdown.selected
	}

func set_data(data: Dictionary) -> void:
	if data.has("player_target"):
		player_dropdown.selected = int(data["player_target"])
	if data.has("action_target"):
		action_dropdown.selected = int(data["action_target"])
