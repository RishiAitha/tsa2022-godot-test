extends Area2D

signal clicked(name) # runs when the tile is clicked

export var opposite_tile = "1-1" # tile on the opposite side of the board, set manually
export var spawn = "none" # if the tile is a spawn point for a certain color, set manually
export var safe = true # if the tile is a safe spot for the end of the round, set manually

func _on_Tile_input_event(_viewport, event, _shape_idx): # on any input event
	if (event is InputEventMouseButton && event.pressed): # if said event is with the mouse button and the button was pressed
		emit_signal("clicked", self.name) # the clicked signal is emitted

