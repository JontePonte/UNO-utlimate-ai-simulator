extends GraphNode

@onready var dropdown = $OptionButton

func _ready():
	# Vilken typ av kort vill vi spela?
	dropdown.add_item("First valid card")
	dropdown.add_item("A special card (+2, Skip, Wild...)")
	dropdown.add_item("A color card")
	
	# Portar: Vänster IN (Vit) aktiv. Höger UT avstängd (detta är ju en action).
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
