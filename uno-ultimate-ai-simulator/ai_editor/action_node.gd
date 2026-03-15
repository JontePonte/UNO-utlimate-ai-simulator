extends GraphNode

func _ready():
	# set_slot(rad_index, vänster_aktiv, vänster_typ, vänster_färg, höger_aktiv, höger_typ, höger_färg)
	# Vänster (In) = true. Höger (Ut) = false.
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
