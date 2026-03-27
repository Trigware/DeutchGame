extends TileMapLayer

@onready var camera = $"../Camera"
@onready var selector = $Selector
@onready var icons = $Icons
@onready var board = $".."

var screen_size: Vector2i
const tile_size := 32
const board_tile_count := Vector2(11, 9)

var possible_moves: Dictionary

func _ready(): load_init_state()
func load_init_state():
	for tile_pos in UID.init_state.piece_locations.keys():
		var piece = UID.init_state.piece_locations[tile_pos]
		var atlas_coord = Vector2i(GridState.piece_atlas_coords_x[piece.kind], 1)
		icons.set_cell(tile_pos, 1, atlas_coord)

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
	if tile_exists and not selector.visible:
		var selected_atlas_coord = get_hovered_atlas_coord(hovered_tile, TileType.Selected)
		set_cell(hovered_tile, 1, selected_atlas_coord)
		previous_hovered_tile = hovered_tile
	
	if not Input.is_action_just_pressed("select_tile"): return
	var selection_cancelled = selected_tile == hovered_tile
	reset_possible_moves()
	if selection_cancelled:
		selected_tile = -Vector2i.ONE
		selector.hide()
		return
	
	if not board.has_piece(hovered_tile): return
	possible_moves = board.get_possible_moves(hovered_tile)
	display_possible_moves()
	selected_tile = hovered_tile
	selector.position = Vector2(selected_tile) * tile_size
	selector.visible = tile_exists
	hide_previous_hovered_tile()

enum TileType {
	Regular,
	Selected,
	Move
}

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
		set_cell(move_dest, 1, get_hovered_atlas_coord(move_dest, TileType.Move))
		var move_cost = possible_moves[move_dest]
		var cost_node = UID.move_cost.instantiate()
		cost_node.position = tile_size * move_dest
		cost_node.size = Vector2(tile_size, tile_size)
		cost_node.text = str(move_cost)
		latest_move_cost_root.add_child(cost_node)
	add_child(latest_move_cost_root)
