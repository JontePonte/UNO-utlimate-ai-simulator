extends GraphNode

func _ready():
	# set_slot-funktionen aktiverar in/utgångar på en specifik rad.
	# Rad 0 är vår första Label ("Evaluate Logic").
	# Parametrar: (rad_index, vänster_aktiv, vänster_typ, vänster_färg, höger_aktiv, höger_typ, höger_färg)
	
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)
