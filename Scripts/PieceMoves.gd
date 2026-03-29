extends Node2D

@onready var tiles = $Tiles

const orthogonal_offsets : Array[Vector2i] =\
	[Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

const diagonal_offsets : Array[Vector2i] =\
	[Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]

const horse_offsets : Array[Vector2i] =\
	[Vector2i(-1, -2), Vector2i(1, -2), Vector2i(-2, -1), Vector2i(2, -1),\
	Vector2i(-2, 1), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(1, 2)]

func has_piece(tile: Vector2i) -> bool: return tile in GridState.active_game.piece_locations.keys()
func get_possible_moves(tile: Vector2i):
	var piece: Piece = GridState.active_game.piece_locations[tile]
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
			var cost = Move.MoveCost.FastTrick if i > 1 else Move.MoveCost.Regular
			result[dest_pos] = Move.ctor(cost, is_in_trick_question(dest_pos))
			if is_stopping_path(piece, dest_pos): break
	for dir in diagonal_offsets:
		var dest_pos = origin + dir
		if not is_valid_tile(piece, dest_pos): continue
		result[dest_pos] = Move.ctor(Move.MoveCost.Fast, is_in_trick_question(dest_pos))
	return result

func get_possible_wizard_moves(piece: Piece, origin: Vector2i) -> Dictionary:
	var result = {}
	var wizard_moves = orthogonal_offsets.duplicate()
	wizard_moves.append_array(diagonal_offsets)
	for dir in wizard_moves:
		var dest_pos = origin + dir
		var is_reviving = is_wizard_reviving(dest_pos)
		var move_invalidated = not is_valid_tile(piece, dest_pos) and not is_reviving
		if move_invalidated: continue
		var is_move_orthogonal = dir in orthogonal_offsets
		var move_cost = Move.MoveCost.Regular
		if is_move_orthogonal: move_cost = Move.MoveCost.Medium
		if is_reviving: move_cost = Move.MoveCost.FastTrick
		result[dest_pos] = Move.ctor(move_cost, is_in_trick_question(dest_pos), is_reviving)
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
	var is_in_wall = tile in GridState.active_game.special_tiles and\
		GridState.active_game.special_tiles[tile].kind == SpecialTile.TileType.Wall
	
	var has_same_team_piece = tile in GridState.active_game.piece_locations and\
		GridState.active_game.piece_locations[tile].team_relation == piece.team_relation
	
	var is_in_grave = is_tile_in_grave(tile)
	var is_invalid = out_of_bounds or is_in_wall or has_same_team_piece or is_in_grave
	return not is_invalid

func is_tile_in_grave(tile: Vector2i) -> bool: return tile in GridState.active_game.grave_tiles
func is_wizard_reviving(tile) -> bool:
	var is_tile_grave = is_tile_in_grave(tile)
	var is_in_piece = tile in GridState.active_game.piece_locations.keys()
	if not is_in_piece or not is_tile_grave: return false
	var revivee: Piece = GridState.active_game.piece_locations[tile]
	var effect_over = revivee.is_effect_over(Effect.StatusEffect.Fainted)
	return effect_over

func is_stopping_path(piece: Piece, tile):
	var is_capturing_piece = tile in GridState.active_game.piece_locations and\
		GridState.active_game.piece_locations[tile].team_relation != piece.team_relation
	if is_capturing_piece: return true
	if is_in_trick_question(tile): return true
	return false

func is_in_trick_question(tile):
	return tile in GridState.active_game.special_tiles and\
		GridState.active_game.special_tiles[tile].kind == SpecialTile.TileType.TrickQuestion
