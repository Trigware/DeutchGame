extends Label

const tile_size = 32

func setup(coord: Vector2i, move: Move, parent: Node):
	position = tile_size * coord
	size = Vector2(tile_size, tile_size)
	text = get_cost_text(move)
	parent.add_child(self)

func get_cost_text(move: Move):
	var duration = Move.move_cost_duration[move.move_cost]
	if move.move_cost == Move.MoveCost.FastTrick: return str(duration) + "s!"
	return str(duration) + "s"
