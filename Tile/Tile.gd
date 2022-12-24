extends Area2D

signal clicked(name)

export var opposite_tile = "1-1"
export var spawn = "none"

func _on_Tile_input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton && event.pressed):
		emit_signal("clicked", self.name)

