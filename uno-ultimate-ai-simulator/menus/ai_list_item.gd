extends PanelContainer

# 1. Skapa signaler som menyn kan lyssna på
signal edit_requested(file_name: String)
signal copy_requested(file_name: String)
signal delete_requested(file_name: String)

@onready var action_buttons = $HBox/ActionButtons
@onready var name_label = $HBox/LabelMargin/Label

# Referenser till knapparna (Se till att namnen stämmer med ditt träd!)
@onready var edit_btn = $HBox/ActionButtons/EditButton
@onready var copy_btn = $HBox/ActionButtons/CopyButton
@onready var delete_btn = $HBox/ActionButtons/RemoveButton

var hover_tween: Tween
var my_file_name: String

func _ready():
	action_buttons.modulate.a = 0.0
	action_buttons.hide()
	
	for child in action_buttons.get_children():
		if child is Button:
			child.mouse_exited.connect(_on_mouse_exited)
			
	# 2. Koppla knapparnas inbyggda "pressed"-signal till våra egna funktioner
	edit_btn.pressed.connect(func(): edit_requested.emit(my_file_name))
	copy_btn.pressed.connect(func(): copy_requested.emit(my_file_name))
	delete_btn.pressed.connect(func(): delete_requested.emit(my_file_name))

# 3. Uppdatera setup_item så den tar emot filnamnet också
func setup_item(display_name: String, file_name: String):
	name_label.text = display_name
	name_label.tooltip_text = display_name
	my_file_name = file_name

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
