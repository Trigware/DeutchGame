extends TileMapLayer

@onready var camera = $"../Camera"
@onready var selector = $Selector
@onready var icons = $Icons
@onready var board = $".."
@onready var status = $Status
@onready var effect_durations = $"Effect Durations"

var screen_size: Vector2i
const tile_size := 32
const board_tile_count := Vector2(11, 9)

var possible_moves: Dictionary

func _ready(): load_init_state()
func load_init_state():
	var state = UID.init_state
	load_kind_of_tile(state.piece_locations, true)
	load_kind_of_tile(state.special_tiles)

func load_kind_of_tile(source: Dictionary, handling_pieces := false):
	for tile_pos in source.keys():
		var tile = source[tile_pos]
		icons.set_cell(tile_pos, 1, tile.get_atlas())
		if not handling_pieces and tile.kind == SpecialTile.TileType.Flag:
			board.grid_state.flag_origin[tile.relation] = tile_pos
		if not handling_pieces: continue
		if tile.kind != GridState.PieceType.Sword: continue
		var grave_pos = tile_pos
		match tile.team_relation:
			SpecialTile.TeamRelation.Red: grave_pos.y += 1
			SpecialTile.TeamRelation.Blue: grave_pos.y -= 1
		board.grid_state.grave_tiles.append(grave_pos)
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

func update_selected_tile():
	var scaled_tile = scale * tile_size
	var mouse_world_pos = get_global_mouse_position()
	hovered_tile = floor((mouse_world_pos - position) / scaled_tile)
	
	var tile_exists = get_cell_source_id(hovered_tile) >= 0
	var hovered_changed = hovered_tile != previous_hovered_tile
	if hovered_changed: hide_previous_hovered_tile()
	var hovering_over_flag_tile = hovered_tile in board.grid_state.flag_origin.values()
	var hovering_over_grave = hovered_tile in board.grid_state.grave_tiles
	var can_highlight_tile = tile_exists and not selector.visible and\
		not hovering_over_flag_tile and not hovering_over_grave
	if can_highlight_tile:
		var selected_atlas_coord = get_hovered_atlas_coord(hovered_tile, TileType.Selected)
		set_cell(hovered_tile, 1, selected_atlas_coord)
		previous_hovered_tile = hovered_tile
	
	if not Input.is_action_just_pressed("select_tile"): return
	
	if selector.visible: play_move_if_possible()
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
	hide_previous_hovered_tile()

enum TileType {
	Regular,
	Selected,
	Move,
	TrickQuestion
}

func can_select(tile: Vector2i) -> bool:
	var has_no_piece = not board.has_piece(tile)
	if has_no_piece: return false
	var is_selectable_color = board.grid_state.piece_locations[tile].team_relation ==\
		board.grid_state.player_turn
	return is_selectable_color

func get_hovered_atlas_coord(tile_pos: Vector2i, tile_type: TileType) -> Vector2i:
	var is_dark = tile_pos.x % 2 != tile_pos.y % 2
	var x_coord = int(is_dark) + tiles_per_variant * int(tile_type)
	return Vector2i(x_coord, 0)

func hide_previous_hovered_tile():
	if previous_hovered_tile == -Vector2i.ONE: return
	set_cell(previous_hovered_tile, 1, get_hovered_atlas_coord(previous_hovered_tile, TileType.Regular))

func reset_possible_moves():
	if latest_move_cost_root != null: latest_move_cost_root.queue_free()
	for move_dist in possible_moves.keys(): set_cell(move_dist, 1, get_hovered_atlas_coord(move_dist, TileType.Regular))

var latest_move_cost_root: Control = null

func display_possible_moves():
	latest_move_cost_root = Control.new()
	
	for move_dest in possible_moves.keys():
		var move: Move = possible_moves[move_dest]
		var tile_type = TileType.TrickQuestion if move.trick_move else TileType.Move
		set_cell(move_dest, 1, get_hovered_atlas_coord(move_dest, tile_type))
		var cost_node = UID.move_cost.instantiate()
		cost_node.setup(move_dest, move, latest_move_cost_root)
	add_child(latest_move_cost_root)

func hide_selector():
	selector.hide()
	selected_tile = -Vector2i.ONE

func play_move_if_possible():
	if hovered_tile == selected_tile: return
	if not hovered_tile in possible_moves.keys():
		hide_selector()
		return
	var piece_locations = board.grid_state.piece_locations
	var moved_piece: Piece = piece_locations[selected_tile]
	piece_locations.erase(selected_tile)
	var has_captured_piece = hovered_tile in piece_locations
	if has_captured_piece: handle_captured_piece_logic()
	piece_locations[hovered_tile] = moved_piece
	icons.erase_cell(selected_tile)
	draw_piece_to_board(moved_piece, hovered_tile)
	selected_tile = hovered_tile
	board.grid_state.next_turn()

func handle_captured_piece_logic():
	var piece_locations = board.grid_state.piece_locations
	var captured_piece: Piece = piece_locations[hovered_tile]
	if captured_piece.kind != GridState.PieceType.Sword: return
	var respawn_pos = captured_piece.respawn_pos
	captured_piece.status_effects = [Effect.ctor(Effect.StatusEffect.Fainted)]
	draw_piece_to_board(captured_piece, respawn_pos)

const status_effect_show_offset : Array[Vector2i] =\
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]

func draw_piece_to_board(piece: Piece, coords: Vector2i):
	icons.set_cell(coords, 1, piece.get_atlas())
	var base_status_coord = coords * 2
	for i in range(piece.status_effects.size()):
		if i >= status_effect_show_offset.size(): break
		var offset = status_effect_show_offset[i]
		var status_show_coord = base_status_coord + offset
		var status_effect: Effect = piece.status_effects[i]
		var status_atlas_coord = status_effect.get_atlas()
		status.set_cell(status_show_coord, 1, status_atlas_coord)
		var effect_node = UID.effect_duration.instantiate()
		effect_node.setup(effect_durations)
