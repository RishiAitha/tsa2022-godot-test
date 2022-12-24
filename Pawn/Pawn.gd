extends Area2D

signal clicked(name)

export var color = "Color"

func _ready():
	var pawns = get_tree().get_nodes_in_group("all_pawns")
	for pawn in pawns:
		if (color == "Blue"):
			$AnimatedSprite.animation = "blue"
		if (color == "Red"):
			$AnimatedSprite.animation = "red"
		if (color == "Yellow"):
			$AnimatedSprite.animation = "yellow"
		if (color == "Green"):
			$AnimatedSprite.animation = "green"

func _on_Pawn_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton && event.pressed):
		emit_signal("clicked", self.name)
