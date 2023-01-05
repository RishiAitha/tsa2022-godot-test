extends Area2D

signal clicked(name) # emitted if the pawn is clicked

export var color = "Color" # color of the pawn, manually set for many purposes such as movement, turns, game over, killing/reviving, etc.

func _ready(): # runs when the pawn is initialized into the scene tree
	var pawns = get_tree().get_nodes_in_group("all_pawns") # takes all pawns in the pawns group
	
	# setting the correct sprites for the pawns
	for pawn in pawns:
		if (color == "Blue"):
			$AnimatedSprite.animation = "blue"
		if (color == "Red"):
			$AnimatedSprite.animation = "red"
		if (color == "Yellow"):
			$AnimatedSprite.animation = "yellow"
		if (color == "Green"):
			$AnimatedSprite.animation = "green"

func _on_Pawn_input_event(_viewport, event, _shape_idx): # when any input event happens, this is run
	if (event is InputEventMouseButton && event.pressed): # if said event is with the mouse button and the button was pressed
		emit_signal("clicked", self.name) # the clicked signal is emitted
