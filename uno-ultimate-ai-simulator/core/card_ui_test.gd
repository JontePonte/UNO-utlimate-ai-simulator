extends Node


var card_ui_scene = preload("res://ui/CardUI.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var visual_card = card_ui_scene.instantiate()
	add_child(visual_card)

	# Testa att skapa ett blått +2 kort!
	var test_card = Card.new(Card.CardColor.BLUE, Card.CardValue.TWO)
	visual_card.set_card_data(test_card)

	# Flytta in det lite på skärmen så det syns
	visual_card.position = Vector2(300, 300)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
