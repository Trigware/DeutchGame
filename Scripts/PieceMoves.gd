extends Node2D

@onready var tiles = $Tiles

var grid_state : GridState = UID.init_state

const orthogonal_offsets : Array[Vector2i] =\
	[Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

const diagonal_offsets : Array[Vector2i] =\
	[Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]

const horse_offsets : Array[Vector2i] =\
	[Vector2i(-1, -2), Vector2i(1, -2), Vector2i(-2, -1), Vector2i(2, -1),\
	Vector2i(-2, 1), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(1, 2)]

func has_piece(tile: Vector2i) -> bool: return tile in grid_state.piece_locations.keys()
func get_possible_moves(tile: Vector2i):
	var piece: Piece = grid_state.piece_locations[tile]
	match piece.kind:
		GridState.PieceType.Sword: return get_possible_sword_moves(piece, tile)
		GridState.PieceType.Wizard: return get_possible_wizard_moves(piece, tile)
		GridState.PieceType.Horse: return get_possible_horse_moves(piece, tile)

const move_range = 2

func get_possible_sword_moves(piece: Piece, origin: Vector2i) -> Dictionary:
	var result = {}
	for dir in orthogonal_offsets:
		for i in range(1, move_range+1):
			var dest_pos = origin + dir * i
			if not is_valid_tile(piece, dest_pos): break
			var is_trick = i > 1
			var cost = Move.MoveCost.FastTrick if is_trick else Move.MoveCost.Regular
			is_trick = is_trick or is_in_trick_question(dest_pos)
			result[dest_pos] = Move.ctor(cost, is_trick)
			if is_stopping_path(piece, dest_pos): break
	for dir in diagonal_offsets:
		var dest_pos = origin + dir
		if not is_valid_tile(piece, dest_pos): continue
		result[dest_pos] = Move.ctor(Move.MoveCost.Fast, is_in_trick_question(dest_pos))
	return result

func get_possible_wizard_moves(piece: Piece, origin: Vector2i) -> Dictionary:
	var result = {}
	for dir in diagonal_offsets:
		var dest_pos = origin + dir
		if is_valid_tile(piece, dest_pos):
			result[dest_pos] = Move.ctor(Move.MoveCost.Medium, is_in_trick_question(dest_pos))
	return result

func get_possible_horse_moves(piece: Piece, origin: Vector2i) -> Dictionary:
	var result = {}
	for dir in horse_offsets:
		var dest_pos = origin + dir
		if is_valid_tile(piece, dest_pos):
			result[dest_pos] = Move.ctor(Move.MoveCost.Medium, is_in_trick_question(dest_pos))
	return result

func is_valid_tile(piece: Piece, tile) -> bool:
	var out_of_bounds = tiles.get_cell_source_id(tile) == -1
	var is_in_wall = tile in grid_state.special_tiles and\
		grid_state.special_tiles[tile].kind == SpecialTile.TileType.Wall
	var has_same_team_piece = tile in grid_state.piece_locations and\
		grid_state.piece_locations[tile].team_relation == piece.team_relation
	var is_in_grave = tile in grid_state.grave_tiles
	var is_invalid = out_of_bounds or is_in_wall or has_same_team_piece or is_in_grave
	return not is_invalid

func is_stopping_path(piece: Piece, tile):
	var is_capturing_piece = tile in grid_state.piece_locations and\
		grid_state.piece_locations[tile].team_relation != piece.team_relation
	if is_capturing_piece: return true
	if is_in_trick_question(tile): return true
	return false

func is_in_trick_question(tile):
	return tile in grid_state.special_tiles and\
		grid_state.special_tiles[tile].kind == SpecialTile.TileType.TrickQuestion
