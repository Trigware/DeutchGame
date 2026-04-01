extends TileMapLayer

@onready var camera = $"../Camera"
@onready var selector = $Selector
@onready var icons = $Icons
@onready var board = $".."
@onready var status = $Status
@onready var effect_durations = $"Effect Durations"
@onready var power_ups = $PowerUps
@onready var game_end = $"../Game End"

var screen_size: Vector2i
const tile_size := 32
const board_tile_count := Vector2(11, 9)

var possible_moves: Dictionary

func _ready(): load_init_state()
func load_init_state():
	GridState.active_game = UID.init_state
	load_kind_of_tile(GridState.active_game.piece_locations, true)
	load_kind_of_tile(GridState.active_game.special_tiles)
	setup_power_ups_at_start()

func setup_power_ups_at_start():
	for tile_coord: Vector2i in GridState.active_game.power_up_tiles:
		GridState.active_game.generate_power_up(tile_coord, power_ups)

func update_board_tile(tile_coord: Vector2i, tile_type: TileType):
	set_cell(tile_coord, 1, get_hovered_atlas_coord(tile_coord, tile_type))

func load_kind_of_tile(source: Dictionary, handling_pieces := false):
	for tile_pos in source.keys():
		var tile = source[tile_pos]
		icons.set_cell(tile_pos, 1, tile.get_atlas())
		if not handling_pieces and tile.kind == SpecialTile.TileType.Flag:
			GridState.active_game.flag_origin[tile.relation] = tile_pos
		if not handling_pieces: continue
		if tile.kind != GridState.PieceType.Sword: continue
		var grave_pos = tile_pos
		match tile.team_relation:
			SpecialTile.TeamRelation.Red: grave_pos.y += 1
			SpecialTile.TeamRelation.Blue: grave_pos.y -= 1
		GridState.active_game.grave_tiles.append(grave_pos)
		tile.respawn_pos = grave_pos

func _process(_delta):
	var current_size = DisplayServer.window_get_size()
	latest_mouse_pos = get_viewport().get_mouse_position()
	update_selected_tile()
	if screen_size == current_size: return
	screen_size = current_size
	update_board()

var zoom_level = 1
var grid_offset := Vector2.ONE

const zoom_change := 1.05
const zoom_limits := Vector2(0.05, 5)

func update_board():
	var board_size = board_tile_count * tile_size
	var intended_scale = Vector2(screen_size) / board_size
	var higher_x_intended = intended_scale.x > intended_scale.y
	var min_scale_component = min(intended_scale.x, intended_scale.y)
	scale = Vector2(min_scale_component, min_scale_component)
	var scaled_board_size = board_size * scale
	
	var used_board_size_component = scaled_board_size.x if higher_x_intended else scaled_board_size.y
	var used_screen_size_component = screen_size.x if higher_x_intended else screen_size.y
	var intended_position = (used_screen_size_component - used_board_size_component) / 2
	var used_x_pos = intended_position if higher_x_intended else 0
	var used_y_pos = 0 if higher_x_intended else intended_position
	position = Vector2(used_x_pos, used_y_pos)
	camera.zoom = Vector2(zoom_level, zoom_level)
	camera.offset = grid_offset

var latest_mouse_pos := Vector2.ZERO

func _unhandled_input(_event):
	var previous_zoom = zoom_level
	var previous_offset = grid_offset
	if Input.is_action_just_pressed("zoom_in"): zoom_level *= zoom_change
	if Input.is_action_just_pressed("zoom_out"): zoom_level /= zoom_change
	if Input.is_action_pressed("pan_grid"):
		var mouse_pos = get_viewport().get_mouse_position()
		var mouse_delta = latest_mouse_pos - mouse_pos
		var offset_delta = Vector2(mouse_delta) * 1 / zoom_level
		grid_offset += offset_delta
	if Input.is_action_just_pressed("cancel_selection"):
		selector.hide()
		reset_possible_moves()
	zoom_level = clamp(zoom_level, zoom_limits.x, zoom_limits.y)
	if previous_zoom == zoom_level and previous_offset == grid_offset: return
	update_board()

var hovered_tile := -Vector2i.ONE
var previous_hovered_tile := hovered_tile
var selected_tile := -Vector2i.ONE
const tiles_per_variant = 2

func handle_mouse_hover_logic():
	var scaled_tile = scale * tile_size
	var mouse_world_pos = get_global_mouse_position()
	hovered_tile = floor((mouse_world_pos - position) / scaled_tile)
	
	var tile_exists = get_cell_source_id(hovered_tile) >= 0
	var hovered_changed = hovered_tile != previous_hovered_tile
	if hovered_changed: hide_previous_hovered_tile()
	
	var can_highlight_tile = tile_exists and not selector.visible and not update_tile_check_states(hovered_tile)
	
	if can_highlight_tile:
		update_board_tile(hovered_tile, TileType.Selected)
		previous_hovered_tile = hovered_tile
	return tile_exists

func update_selected_tile():
	var tile_exists = handle_mouse_hover_logic()
	if not Input.is_action_just_pressed("select_tile"): return
	
	if selector.visible: play_move_if_possible()
	hide_previous_hovered_tile()
	var selection_cancelled = selected_tile == hovered_tile
	reset_possible_moves()
	if selection_cancelled:
		hide_selector()
		return
	
	if not can_select(hovered_tile): return
	possible_moves = board.get_possible_moves(hovered_tile)
	display_possible_moves()
	selected_tile = hovered_tile
	selector.position = Vector2(selected_tile) * tile_size
	selector.visible = tile_exists

enum TileType {
	Regular,
	Selected,
	Move,
	TrickQuestion,
	Grave,
	Flag,
}

func can_select(tile: Vector2i) -> bool:
	var has_no_piece = not board.has_piece(tile)
	if has_no_piece: return false
	var selected_piece: Piece = GridState.active_game.piece_locations[tile]
	var is_selectable_color = selected_piece.team_relation == GridState.active_game.player_turn
	var is_selecting_non_fainted_piece = not selected_piece.has_status_effect(Effect.StatusEffect.Fainted)
	var is_game_ongoing = GridState.active_game.game_end_type == GridState.GameEndType.Ongoing
	var can_be_selected = is_selectable_color and is_selecting_non_fainted_piece and is_game_ongoing
	return can_be_selected

const last_tile_pair := TileType.TrickQuestion

func get_hovered_atlas_coord(tile_pos: Vector2i, tile_type: TileType) -> Vector2i:
	var is_dark = tile_pos.x % 2 != tile_pos.y % 2
	var used_tile_type = min(tile_type, last_tile_pair)
	var x_coord = tiles_per_variant * int(used_tile_type)
	if tile_type <= last_tile_pair: x_coord += int(is_dark)
	else: x_coord += tile_type - last_tile_pair + 1
	return Vector2i(x_coord, 0)

func hide_previous_hovered_tile():
	if previous_hovered_tile == -Vector2i.ONE: return
	update_board_tile(previous_hovered_tile, TileType.Regular)

var latest_check_grave_tile: bool
var latest_check_is_flag: bool

func update_tile_check_states(tile_coord: Vector2i) -> bool:
	latest_check_grave_tile = tile_coord in GridState.active_game.grave_tiles
	latest_check_is_flag = tile_coord in GridState.active_game.flag_origin.values()
	return latest_check_grave_tile or latest_check_is_flag

func reset_possible_moves():
	if latest_move_cost_root != null: latest_move_cost_root.queue_free()
	for move_dist in possible_moves.keys():
		update_tile_check_states(move_dist)
		var tile_type = TileType.Regular
		if latest_check_grave_tile: tile_type = TileType.Grave
		if latest_check_is_flag: tile_type = TileType.Flag
		update_board_tile(move_dist, tile_type)

var latest_move_cost_root: Control = null

func display_possible_moves():
	latest_move_cost_root = Control.new()
	
	for move_dest in possible_moves.keys():
		var move: Move = possible_moves[move_dest]
		var tile_type = TileType.TrickQuestion if move.trick_move else TileType.Move
		update_board_tile(move_dest, tile_type)
		var cost_node = UID.move_cost.instantiate()
		cost_node.setup(move_dest, move, latest_move_cost_root)
	add_child(latest_move_cost_root)
	previous_hovered_tile = -Vector2i.ONE

func hide_selector():
	selector.hide()
	selected_tile = -Vector2i.ONE

func play_move_if_possible():
	if hovered_tile == selected_tile: return
	if not hovered_tile in possible_moves.keys():
		hide_selector()
		return
	play_move()

func play_move():
	var current_move: Move = possible_moves[hovered_tile]
	var wizard_is_reviving = current_move.is_reviving
	GridState.active_game.next_turn()
	var piece_locations = GridState.active_game.piece_locations
	var moved_piece: Piece = piece_locations[selected_tile]
	var has_captured_piece = hovered_tile in piece_locations
	if has_captured_piece: handle_captured_piece_logic()
	
	if wizard_is_reviving:
		var revived_piece: Piece = piece_locations[hovered_tile]
		revived_piece.remove_all_effects()
		draw_piece_to_board(revived_piece, hovered_tile)
		selected_tile = hovered_tile
		return
	
	handle_flag_move_logic(moved_piece)
	erase_piece(selected_tile)
	piece_locations[hovered_tile] = moved_piece
	icons.erase_cell(selected_tile)
	draw_piece_to_board(moved_piece, hovered_tile)
	handle_power_up_tiles()
	handle_win_conditions(moved_piece)
	if GridState.active_game.game_end_type != GridState.GameEndType.Ongoing:
		game_end.display_end_of_game()
	selected_tile = hovered_tile

func handle_flag_move_logic(moved_piece: Piece):
	var obtainted_flag = hovered_tile in GridState.active_game.flag_origin.values()
	if not obtainted_flag: return
	var used_flag = Effect.StatusEffect.BlueFlag if moved_piece.team_relation == SpecialTile.TeamRelation.Red\
		else Effect.StatusEffect.RedFlag
	moved_piece.add_effect(used_flag)

func handle_captured_piece_logic():
	var piece_locations = GridState.active_game.piece_locations
	var captured_piece: Piece = piece_locations[hovered_tile]
	var captured_had_flag = captured_piece.has_flag()
	
	if captured_had_flag:
		var flag_team = captured_piece.flag_kind()
		var respawn_coord = GridState.active_game.flag_origin[flag_team]
		var special_tile = SpecialTile.flag(flag_team)
		GridState.active_game.special_tiles[respawn_coord] = special_tile
		icons.set_cell(respawn_coord, 1, special_tile.get_atlas())
	
	if captured_piece.kind != GridState.PieceType.Sword: return
	var respawn_pos = captured_piece.respawn_pos
	captured_piece.override_effects(Effect.StatusEffect.Fainted)
	piece_locations[respawn_pos] = captured_piece
	draw_piece_to_board(captured_piece, respawn_pos)

const status_effect_show_offset : Array[Vector2i] =\
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]

func draw_piece_to_board(piece: Piece, coords: Vector2i):
	icons.set_cell(coords, 1, piece.get_atlas())
	var base_status_coord = coords * 2
	var effect_count = piece.status_effects.size()
	for i in range(status_effect_show_offset.size()):
		var offset = status_effect_show_offset[i]
		var status_show_coord = base_status_coord + offset
		status.erase_cell(status_show_coord)
		if i >= effect_count: continue
		var status_effect: Effect = piece.status_effects.values()[i]
		if status_effect.effect_type == Effect.StatusEffect.Unknown: continue
		var status_atlas_coord = status_effect.get_atlas()
		status.set_cell(status_show_coord, 1, status_atlas_coord)
		var effect_node = UID.effect_duration.instantiate()
		effect_node.setup(status_show_coord, status_effect, effect_durations)

func erase_piece(coords: Vector2i):
	var piece_locations = GridState.active_game.piece_locations
	piece_locations.erase(selected_tile)
	var base_status_coord = coords * 2
	for i in range(status_effect_show_offset.size()):
		var status_coord = base_status_coord + status_effect_show_offset[i]
		status.erase_cell(status_coord)

func handle_power_up_tiles():
	var contains_power_up = GridState.active_game.has_tile_power_up(hovered_tile)
	if not contains_power_up: return
	var obtainted_kind = GridState.active_game.power_up_tiles[hovered_tile]
	GridState.active_game.power_up_tiles.erase(hovered_tile)
	power_ups.erase_cell(hovered_tile)
	GridState.active_game.receive_power_up(obtainted_kind)

func handle_win_conditions(moved_piece: Piece):
	var needed_flag_color = moved_piece.team_relation
	var is_in_flag_origin = GridState.active_game.flag_origin[needed_flag_color] == hovered_tile
	var holds_flag = moved_piece.has_flag()
	var has_obtainted_flag = is_in_flag_origin and holds_flag
	if has_obtainted_flag:
		GridState.active_game.game_end_type = GridState.GameEndType.FlagCaptured
		return
	var unable_to_progress = board.is_lack_of_moves_win_condition_valid()
	if not unable_to_progress: return
	GridState.active_game.game_end_type = GridState.GameEndType.PiecelessOpponent
