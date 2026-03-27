extends Node2D

@onready var tiles = $Tiles

var grid_state := UID.init_state

func has_piece(tile: Vector2i) -> bool: return tile in grid_state.piece_locations.keys()
