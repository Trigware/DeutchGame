extends Node2D

@onready var tiles = $Tiles

var grid_state := UID.init_state

func has_piece(tile: Vector2i) -> bool: return tile in grid_state.piece_locations.keys()
func get_possible_moves(tile: Vector2i) -> Dictionary[Vector2i, int]:
	return {
		Vector2i(tile.x, tile.y - 1): 1,
		Vector2i(tile.x, tile.y + 1): 2
	}
