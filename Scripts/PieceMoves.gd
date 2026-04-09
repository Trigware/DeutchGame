extends Node2D

@onready var tiles = $Tiles

var grid_shadow: TileMapLayer = null

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
	var is_frozen = piece.has_status_effect(Effect.StatusEffect.Frozen)
	if is_frozen: return {}
	match piece.kind:
		GridState.PieceType.Sword: return get_possible_sword_moves(piece, tile)
		GridState.PieceType.Wizard: return get_possible_wizard_moves(piece, tile)
		GridState.PieceType.Horse: return get_possible_horse_moves(piece, tile)

const move_range = 2

func _process(_delta):
	create_grid_shadow()

const grid_shadow_offset = Vector2(10, 12)

func create_grid_shadow():
	if grid_shadow != null: grid_shadow.queue_free()
	grid_shadow = tiles.duplicate()
	for child in grid_shadow.get_children(true): child.queue_free()
	grid_shadow.position += Vector2.ONE * grid_shadow_offset * tiles.scale
	grid_shadow.set_script(null)
	grid_shadow.z_index = -1
	grid_shadow.modulate = Color.BLACK
	add_child(grid_shadow)

func get_possible_sword_moves(piece: Piece, origin: Vector2i) -> Dictionary:
	var result = {}
	var actual_range = move_range
	var is_slow = piece.has_status_effect(Effect.StatusEffect.Slowness)
	var is_fast = piece.has_status_effect(Effect.StatusEffect.Speed)
	if is_fast: actual_range += 1
	for dir in orthogonal_offsets:
		for i in range(1, actual_range+1):
			var dest_pos = origin + dir * i
			if not is_valid_tile(piece, dest_pos): break
			var cost = Move.MoveCost.FastTrick if i > 1 else Move.MoveCost.Regular
			result[dest_pos] = Move.ctor(cost, is_in_trick_question(dest_pos))
			if is_stopping_path(piece, dest_pos): break
	if is_slow: return result
	
	for dir in diagonal_offsets:
		var dest_pos = origin + dir
		if not is_valid_tile(piece, dest_pos): continue
		result[dest_pos] = Move.ctor(Move.MoveCost.Fast, is_in_trick_question(dest_pos))
	return result

func get_possible_wizard_moves(piece: Piece, origin: Vector2i) -> Dictionary:
	var result = {}
	var wizard_moves = orthogonal_offsets.duplicate()
	var is_slow = piece.has_status_effect(Effect.StatusEffect.Slowness)
	if not is_slow: wizard_moves.append_array(diagonal_offsets)
	var wizard_range = 1
	if piece.has_status_effect(Effect.StatusEffect.Speed): wizard_range += 1
	for dir in wizard_moves:
		for i in range(1, wizard_range+1):
			var dest_pos = origin + dir * i
			var is_reviving = is_wizard_reviving(dest_pos)
			var is_freezing_piece = not is_reviving and is_in_piece(dest_pos)
			var move_attribute = Move.Attribute.None
			if is_reviving: move_attribute = Move.Attribute.SwordRevive
			if is_freezing_piece: move_attribute = Move.Attribute.PieceFreeze
			
			var move_invalidated = not is_valid_tile(piece, dest_pos) and not is_reviving
			if move_invalidated: break
			
			var is_move_orthogonal = dir in orthogonal_offsets
			var move_cost = Move.MoveCost.Regular
			if is_move_orthogonal: move_cost = Move.MoveCost.Medium
			var has_attribute = move_attribute != Move.Attribute.None
			if has_attribute or i > 1: move_cost = Move.MoveCost.FastTrick
			result[dest_pos] = Move.ctor(move_cost, is_in_trick_question(dest_pos), move_attribute)
			if is_stopping_path(piece, dest_pos): break
	return result

func get_possible_horse_moves(piece: Piece, origin: Vector2i) -> Dictionary:
	var result = {}
	for dir in horse_offsets:
		var dest_pos = origin + dir
		if not is_valid_tile(piece, dest_pos): continue
		result[dest_pos] = Move.ctor(Move.MoveCost.Medium, is_in_trick_question(dest_pos))
	return result

func is_valid_tile(piece: Piece, tile) -> bool:
	var out_of_bounds = tiles.get_cell_source_id(tile) == -1
	var is_in_wall = tile in GridState.active_game.special_tiles and\
		GridState.active_game.special_tiles[tile].kind == SpecialTile.TileType.Wall
	
	var capturing_piece = tile in GridState.active_game.piece_locations
	var has_same_team_piece = capturing_piece and GridState.active_game.piece_locations[tile].team_relation == piece.team_relation
	
	var is_in_grave = is_tile_in_grave(tile)
	var attempting_to_capture_protected = capturing_piece and GridState.active_game.piece_locations[tile].has_status_effect(Effect.StatusEffect.Protected)
	var is_capture_frozen = capturing_piece and GridState.active_game.piece_locations[tile].has_status_effect(Effect.StatusEffect.Frozen)
	
	var is_invalid = out_of_bounds or is_in_wall or has_same_team_piece or is_in_grave or attempting_to_capture_protected or is_capture_frozen
	return not is_invalid

func is_tile_in_grave(tile: Vector2i) -> bool: return tile in GridState.active_game.grave_tiles
func is_wizard_reviving(tile) -> bool:
	var is_tile_grave = is_tile_in_grave(tile)
	var in_piece = is_in_piece(tile)
	if not in_piece or not is_tile_grave: return false
	var revivee: Piece = GridState.active_game.piece_locations[tile]
	var effect_over = revivee.is_effect_over(Effect.StatusEffect.Fainted)
	return effect_over

func is_in_piece(tile) -> bool:
	return tile in GridState.active_game.piece_locations.keys()

func is_stopping_path(piece: Piece, tile):
	var is_capturing_piece = tile in GridState.active_game.piece_locations and\
		GridState.active_game.piece_locations[tile].team_relation != piece.team_relation
	if is_capturing_piece: return true
	if is_in_trick_question(tile): return true
	return false

func is_in_trick_question(tile):
	var in_special_tile = tile in GridState.active_game.special_tiles
	if not in_special_tile: return false
	var special_tile: SpecialTile = GridState.active_game.special_tiles[tile]
	var is_tricky_question = special_tile.kind == SpecialTile.TileType.TrickQuestion
	if not is_tricky_question: return false
	var is_general_question = special_tile.relation == SpecialTile.TeamRelation.Other
	var is_same_color = special_tile.relation == GridState.active_game.player_turn
	var is_correct_color = is_general_question or is_same_color
	return is_correct_color

func is_lack_of_moves_win_condition_valid() -> bool:
	var number_of_valid_pieces = 0
	for piece_coord: Vector2i in GridState.active_game.piece_locations:
		var piece: Piece = GridState.active_game.piece_locations[piece_coord]
		var opponent_piece = piece.team_relation != GridState.active_game.player_turn
		var piece_has_fainted = Effect.StatusEffect.Fainted in piece.status_effects
		if opponent_piece or piece_has_fainted: continue
		number_of_valid_pieces += 1
	return number_of_valid_pieces == 0
