extends PanelContainer

@onready var action_buttons = $HBox/ActionButtons
@onready var name_label = $HBox/LabelMargin/Label

var hover_tween: Tween

func _ready():
	action_buttons.modulate.a = 0.0
	action_buttons.hide()
	
	# --- NYTT: Lyssna även på när musen lämnar knapparna! ---
	for child in action_buttons.get_children():
		if child is Button:
			child.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if hover_tween:
		hover_tween.kill()
	
	action_buttons.show()
	hover_tween = create_tween()
	hover_tween.tween_property(action_buttons, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	# --- NYTT: Vänta en mikrosekund så musens position hinner uppdateras i Godot ---
	await get_tree().process_frame
	
	# Är musen fortfarande inuti hela radens område?
	var mouse_pos = get_global_mouse_position()
	if get_global_rect().has_point(mouse_pos):
		return # Gör ingenting, vi är t.ex. bara mellan två knappar
		
	# Musen har VERKLIGEN lämnat raden, dags att tona ut!
	if hover_tween:
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.tween_property(action_buttons, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween.tween_callback(action_buttons.hide)

func setup_item(ai_name: String):
	name_label.text = ai_name
	
	# Detta magiska lilla kommando skapar hover-effekten med hela namnet!
	name_label.tooltip_text = ai_name
