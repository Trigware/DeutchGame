class_name GridTiles
extends TileMapLayer

@onready var camera = $"../Camera"
@onready var selector = $Selector
@onready var icons = $Icons
@onready var board = $".."
@onready var status = $Status
@onready var effect_durations = $"Effect Durations"
@onready var power_ups = $PowerUps
@onready var game_end = $"../Game End"
@onready var items = $"../Items"
@onready var special_tiles = $"Special Tiles"
@onready var tiled_diagonals = $"../Tiled Diagonals"
@export var tutorial_ui: TutorialUI

var screen_size: Vector2i
const tile_size := 32
const board_tile_count := Vector2(11, 9)

var possible_moves: Dictionary

func _ready():
	var initial_game_state = UID.tutorial_state if board.is_playing_tutorial else UID.init_state
	load_state(initial_game_state, true)

func load_state(state_to_be_loaded, forced = false):
	var saved_tutorial_index = TutorialUI.start_dialog_index - 1
	var saved_ingredients_encountered = []
	var saved_foods_encountered = []
	var saved_minigame_explained = false
	if GameState.active_game != null:
		saved_tutorial_index = GameState.active_game.current_dialog_index
		saved_ingredients_encountered = GameState.active_game.ingredients_encountered
		saved_foods_encountered = GameState.active_game.foods_encountered
	
	icons.clear()
	status.clear()
	power_ups.clear()
	special_tiles.clear()
	clear_effect_durations()
	
	if not board.returned_to_board: GameState.active_game = UID.init_state
	if GameState.active_game == null or forced: GameState.active_game = state_to_be_loaded
	GameState.active_game.current_dialog_index = saved_tutorial_index
	
	GameState.active_game.grid_tiles = self
	load_kind_of_tile(GameState.active_game.piece_locations, true)
	load_kind_of_tile(GameState.active_game.special_tiles)
	tiled_diagonals.line_color = GameState.active_game.diagonals_modulate[GameState.active_game.player_turn]
	if board.returned_to_board: load_power_up_tiles()
	else: setup_power_ups_at_start()
	if board.returned_to_board: handle_after_minigame_return()

func clear_effect_durations():
	for effect_dur_node in effect_durations.get_children():
		effect_dur_node.queue_free()

func handle_after_minigame_return():
	var was_task_successful = board.task_was_successful
	var played_sfx = UID.task_success_sfx if was_task_successful else UID.task_failure_sfx
	Audio.play_sound(played_sfx)

func setup_power_ups_at_start():
	for tile_coord: Vector2i in GameState.active_game.power_up_tiles: GameState.active_game.generate_power_up(tile_coord, power_ups)

func load_power_up_tiles():
	for tile_coord: Vector2i in GameState.active_game.power_up_tiles: GameState.active_game.update_power_up_tile(tile_coord, power_ups)

func update_board_tile(tile_coord: Vector2i, tile_type: TileType):
	set_cell(tile_coord, 1, get_hovered_atlas_coord(tile_coord, tile_type))

const default_grave_tiles : Array[Vector2i] = [Vector2i(3, 0), Vector2i(7, 0), Vector2(3, 8), Vector2i(7, 8)]

func load_kind_of_tile(source: Dictionary, handling_pieces := false):
	for tile_pos in source.keys():
		var tile = source[tile_pos]
		var tile_map = null
		var using_icons_map = tile is SpecialTile and tile.kind == SpecialTile.TileType.Wall or handling_pieces
		if using_icons_map: tile_map = icons
		else: tile_map = special_tiles
		
		tile_map.set_cell(tile_pos, 1, tile.get_atlas())
		if not handling_pieces and tile.kind == SpecialTile.TileType.Flag and not board.returned_to_board:
			GameState.active_game.flag_origin[tile.relation] = tile_pos
		if not handling_pieces: continue
		var piece_value = GameState.active_game.piece_locations[tile_pos]
		draw_piece_to_board(piece_value, tile_pos)
		if tile.kind != GridState.PieceType.Sword or board.returned_to_board: continue
		
		var grave_pos = tile_pos
		match tile.team_relation:
			SpecialTile.TeamRelation.Red: grave_pos.y += 1
			SpecialTile.TeamRelation.Blue: grave_pos.y -= 1
		if tile.respawn_pos == -Vector2i.ONE: tile.respawn_pos = grave_pos
	
	GameState.active_game.grave_tiles = default_grave_tiles

func _process(_delta):
	var current_size = DisplayServer.window_get_size()
	latest_mouse_pos = get_viewport().get_mouse_position()
	update_selected_tile()
	if screen_size == current_size: return
	screen_size = current_size
	update_board()

var zoom_level : float = 1
var grid_offset := Vector2.ZERO

const zoom_change := 1.05
const zoom_limits := Vector2(0.075, 10)
const diagonal_scale_multiplier := 1.5

func update_board():
	tiled_diagonals.scale = Vector2.ONE * (1.0 / zoom_level) * diagonal_scale_multiplier
	tiled_diagonals.position_offset = grid_offset
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
	
	var window_size = DisplayServer.window_get_size()
	tiled_diagonals.size = window_size
	position = Vector2(used_x_pos, used_y_pos)
	camera.zoom = Vector2(zoom_level, zoom_level)
	camera.offset = grid_offset
	camera.position = window_size / 2

var latest_mouse_pos := Vector2.ZERO

func _input(_event):
	var previous_zoom = zoom_level
	var previous_offset = grid_offset
	if Input.is_action_just_pressed("zoom_in"): zoom_level *= zoom_change
	if Input.is_action_just_pressed("zoom_out"): zoom_level /= zoom_change
	if Input.is_action_pressed("pan_grid"):
		var mouse_pos = get_viewport().get_mouse_position()
		var mouse_delta = latest_mouse_pos - mouse_pos
		var offset_delta = Vector2(mouse_delta) * 1 / zoom_level
		grid_offset += offset_delta
	if Input.is_action_just_pressed("pause_menu") and not selector.visible:
		game_end.display_menu()
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

func get_hovered_tile() -> Vector2i:
	var scaled_tile = scale * tile_size
	var mouse_world_pos = get_global_mouse_position()
	var result = floor((mouse_world_pos - position) / scaled_tile)
	return result

var entering_trick_question = false

func handle_mouse_hover_logic():
	hovered_tile = get_hovered_tile()
	var tile_exists = get_cell_source_id(hovered_tile) >= 0
	var hovered_changed = hovered_tile != previous_hovered_tile
	if hovered_changed: hide_previous_hovered_tile()
	
	var can_highlight_tile = tile_exists and not selector.visible and\
		not update_tile_check_states(hovered_tile) and items.highlighted_tiles.size() == 0 and not entering_trick_question
	
	if can_highlight_tile:
		update_board_tile(hovered_tile, TileType.Selected)
		previous_hovered_tile = hovered_tile
	return tile_exists

func update_selected_tile():
	var tile_exists = handle_mouse_hover_logic()
	var is_clicking = Input.is_action_just_pressed("select_tile")
	var selecting_tile = is_clicking and not items.dragging_power_up
	if not selecting_tile: return
	
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
	var selected_piece: Piece = GameState.active_game.piece_locations[tile]
	var is_selectable_color = selected_piece.team_relation == GameState.active_game.player_turn
	var is_selecting_non_fainted_piece = not selected_piece.has_status_effect(Effect.StatusEffect.Fainted)
	var is_game_ongoing = GameState.active_game.game_end_type == GridState.GameEndType.Ongoing
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
	latest_check_grave_tile = tile_coord in GameState.active_game.grave_tiles
	latest_check_is_flag = tile_coord in GameState.active_game.flag_origin.values()
	return latest_check_grave_tile or latest_check_is_flag

func reset_possible_moves():
	if latest_move_cost_root != null: latest_move_cost_root.queue_free()
	for move_dist in possible_moves.keys():
		reset_board_tile(move_dist)

var latest_move_cost_root: Control = null

func reset_board_tile(tile_coord: Vector2i):
	update_tile_check_states(tile_coord)
	var tile_type = TileType.Regular
	if latest_check_grave_tile: tile_type = TileType.Grave
	if latest_check_is_flag: tile_type = TileType.Flag
	update_board_tile(tile_coord, tile_type)

func display_possible_moves():
	latest_move_cost_root = Control.new()
	
	for move_dest in possible_moves.keys():
		var move: Move = possible_moves[move_dest]
		var tile_type = TileType.TrickQuestion if move.trick_move else TileType.Move
		update_board_tile(move_dest, tile_type)
		var cost_node = UID.move_cost.instantiate()
		cost_node.board_root = board
		cost_node.setup(move_dest, move, latest_move_cost_root)
	add_child(latest_move_cost_root)
	previous_hovered_tile = -Vector2i.ONE

func hide_selector():
	selector.hide()
	selected_tile = -Vector2i.ONE

func play_move_if_possible():
	if hovered_tile == selected_tile: return
	var is_tutorial_move_invalid = board.is_playing_tutorial and not is_tutorial_move_valid()
	var is_move_blocked = not hovered_tile in possible_moves.keys() or is_tutorial_move_invalid
	if is_move_blocked:
		hide_selector()
		return
	play_move()

const tutorial_piece_interaction_dialog_indices := [
	TutorialUI.TutorialDialogType.CapturingSwords,
	TutorialUI.TutorialDialogType.RevivingSwords
]

const moving_invalid_tutorial_dialog_index = TutorialUI.TutorialDialogType.GameObjective

func is_tutorial_move_valid():
	if not tutorial_ui.can_progress_tutorial: return false
	var dialog_index = GameState.active_game.current_dialog_index
	if dialog_index == moving_invalid_tutorial_dialog_index: return false
	if dialog_index >= TutorialUI.TutorialDialogType.PowerUpRules: return true
	
	var is_interacting_with_piece = dialog_index in tutorial_piece_interaction_dialog_indices
	if is_interacting_with_piece: return hovered_tile in GameState.active_game.piece_locations.keys()
	return true

signal tutorial_move_played

const switch_player_turn_allowed_tutorial_indices := [TutorialUI.TutorialDialogType.CapturingSwords, TutorialUI.TutorialDialogType.PowerUpRules, TutorialUI.TutorialDialogType.GameObjective]

func switch_player_turn():
	var tutorial_dialog_index = GameState.active_game.current_dialog_index
	var player_turn_disabled = not tutorial_dialog_index in switch_player_turn_allowed_tutorial_indices and board.is_playing_tutorial
	if player_turn_disabled: return
	
	GameState.active_game.next_turn()
	var diagonal_color = GridState.diagonals_modulate[GameState.active_game.player_turn]
	tiled_diagonals.change_color(diagonal_color)

func play_move(called_after_event = false):
	var current_move: Move = GameState.active_game.latest_move if called_after_event\
		else possible_moves[hovered_tile]
	GameState.active_game.latest_move = current_move
	point_sources.clear()
	
	if not called_after_event: switch_player_turn()
	var piece_locations = GameState.active_game.piece_locations
	var moved_piece: Piece = piece_locations[selected_tile]
	var affected_piece: Piece = null
	var has_captured_piece = hovered_tile in piece_locations
	if has_captured_piece: affected_piece = piece_locations[hovered_tile]
	
	var handle_event = not questions_minigames_disabled and not called_after_event and not board.is_playing_tutorial
	var is_tutorial_progress_enabled = GameState.active_game.current_dialog_index in TutorialUI.disabled_tutorial_progress_dialog_indices
	if board.is_playing_tutorial and is_tutorial_progress_enabled: tutorial_move_played.emit()
	if handle_event:
		handle_pre_move_event(current_move)
		return
	
	match current_move.attribute:
		Move.Attribute.SwordRevive:
			revive_piece(affected_piece)
			return
		Move.Attribute.PieceFreeze:
			freeze_piece(affected_piece)
			return
	
	var completed_source = PointSource.CompletedMinigame if board.returned_from_minigame else PointSource.CorrectAnswer
	point_sources.append(completed_source)
	if has_captured_piece:
		affected_piece = piece_locations[hovered_tile]
		handle_captured_piece_logic()
	
	handle_flag_move_logic(moved_piece)
	erase_piece(selected_tile)
	piece_locations[hovered_tile] = moved_piece
	icons.erase_cell(selected_tile)
	draw_piece_to_board(moved_piece, hovered_tile)
	handle_power_up_regeneration()
	handle_power_up_tiles()
	handle_win_conditions(moved_piece)
	update_points()
	
	if GameState.active_game.game_end_type != GridState.GameEndType.Ongoing:
		GameState.active_game.invert_turn()
		game_end.display_menu()
	selected_tile = hovered_tile
	Save.save_game()

func has_entered_tile_with_trick(current_move: Move):
	return current_move.trick_move or hovered_tile in GameState.active_game.special_tiles and\
		GameState.active_game.special_tiles[hovered_tile].kind == SpecialTile.TileType.TrickQuestion

func revive_piece(revived_piece: Piece):
	revived_piece.remove_all_effects()
	draw_piece_to_board(revived_piece, hovered_tile)
	selected_tile = hovered_tile

func freeze_piece(frozen_piece: Piece):
	frozen_piece.add_effect(Effect.StatusEffect.Frozen)
	draw_piece_to_board(frozen_piece, hovered_tile)
	selected_tile = hovered_tile

func handle_flag_move_logic(moved_piece: Piece):
	var on_special_tile = hovered_tile in GameState.active_game.special_tiles
	if not on_special_tile: return
	
	var dest_special_tile : SpecialTile = GameState.active_game.special_tiles[hovered_tile]
	var on_correct_relation = moved_piece.team_relation != dest_special_tile.relation
	var flag_exists = GameState.active_game.special_tiles[hovered_tile].is_flag()
	var obtainted_flag = flag_exists and on_correct_relation
	if not obtainted_flag: return
	
	var used_flag = Effect.StatusEffect.BlueFlag if moved_piece.team_relation == SpecialTile.TeamRelation.Red\
		else Effect.StatusEffect.RedFlag
	moved_piece.add_effect(used_flag)
	point_sources.append(PointSource.ObtaintedFlag)
	special_tiles.erase_cell(hovered_tile)
	GameState.active_game.special_tiles.erase(hovered_tile)

func handle_captured_piece_logic():
	var piece_locations = GameState.active_game.piece_locations
	var captured_piece: Piece = piece_locations[hovered_tile]
	var captured_had_flag = captured_piece.has_flag()
	
	if captured_had_flag:
		var flag_team: SpecialTile.TeamRelation = captured_piece.flag_kind()
		var respawn_coord = GameState.active_game.flag_origin[flag_team]
		var special_tile = SpecialTile.flag(flag_team)
		GameState.active_game.special_tiles[respawn_coord] = special_tile
		special_tiles.set_cell(respawn_coord, 1, special_tile.get_atlas())
		captured_piece.remove_flag()
		GameState.active_game.special_tiles[respawn_coord] = special_tile
		point_sources.append(PointSource.ReturnedFlag)
	
	var has_captured_sword = captured_piece.kind == GridState.PieceType.Sword
	var can_revive_sword = has_captured_sword and is_wizard_alive()
	var point_source = PointSource.CapturedSword if can_revive_sword else PointSource.KilledPiece
	point_sources.append(point_source)
	if not has_captured_sword: return
	
	var respawn_pos = captured_piece.respawn_pos
	captured_piece.override_effects(Effect.StatusEffect.Fainted)
	piece_locations[respawn_pos] = captured_piece
	draw_piece_to_board(captured_piece, respawn_pos)

func is_wizard_alive():
	for piece_pos in GameState.active_game.piece_locations.keys():
		var piece_data = GameState.active_game.piece_locations[piece_pos]
		var is_correct_color = piece_data.team_relation == GameState.active_game.player_turn
		var is_wizard = piece_data.kind == GridState.PieceType.Wizard
		if is_correct_color and is_wizard: return true
	return false

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
		if status_effect.duration_node != null:
			status_effect.duration_node.queue_free()
		if status_effect.effect_type == Effect.StatusEffect.Unknown: continue
		var status_atlas_coord = status_effect.get_atlas()
		status.set_cell(status_show_coord, 1, status_atlas_coord)
		var effect_node = UID.effect_duration.instantiate()
		effect_node.setup(status_show_coord, status_effect, effect_durations)

func erase_piece(coords: Vector2i):
	var piece_locations = GameState.active_game.piece_locations
	piece_locations.erase(selected_tile)
	var base_status_coord = coords * 2
	for i in range(status_effect_show_offset.size()):
		var status_coord = base_status_coord + status_effect_show_offset[i]
		status.erase_cell(status_coord)

func handle_power_up_tiles():
	var contains_power_up = GameState.active_game.has_tile_power_up(hovered_tile)
	if not contains_power_up: return
	
	var obtainted_kind = GameState.active_game.power_up_tiles[hovered_tile]
	GameState.active_game.power_up_tiles.erase(hovered_tile)
	power_ups.erase_cell(hovered_tile)
	point_sources.append(PointSource.ObtaintedPowerUp)
	GameState.active_game.receive_power_up(hovered_tile, obtainted_kind)

func handle_win_conditions(moved_piece: Piece):
	if board.is_playing_tutorial: return
	var needed_flag_color = moved_piece.team_relation
	var flag_origin_dict = GameState.active_game.flag_origin
	if not needed_flag_color in flag_origin_dict: return
	
	var is_in_flag_origin = flag_origin_dict[needed_flag_color] == hovered_tile
	var holds_flag = moved_piece.has_flag()
	var has_obtainted_flag = is_in_flag_origin and holds_flag
	if has_obtainted_flag:
		GameState.active_game.game_end_type = GridState.GameEndType.FlagCaptured
		return
	
	var unable_to_progress = board.is_lack_of_moves_win_condition_valid()
	if not unable_to_progress: return
	GameState.active_game.game_end_type = GridState.GameEndType.PiecelessOpponent

var trick_question_transition_duration = 0.35
const full_zoom : float = 3
const trick_transition_duration = 0.75

const questions_minigames_disabled = false
const after_trick_question_scene = UID.trick_question_decision

func handle_pre_move_event(current_move: Move):
	var entered_trick_question = has_entered_tile_with_trick(current_move)
	var next_scene = after_trick_question_scene if entered_trick_question else UID.question_scene
	
	var center_grid_tile = (board_tile_count - Vector2.ONE) / 2
	var offset_from_center = Vector2(selected_tile) - center_grid_tile
	var absolute_offset = offset_from_center * tile_size * scale
	
	entering_trick_question = true
	GameState.active_game.trick_move_origin = selected_tile
	GameState.active_game.trick_move_destination = hovered_tile
	selected_tile = hovered_tile
	
	var instantiated_scene = next_scene.instantiate()
	if instantiated_scene is Question: instantiated_scene.question_total_time = Move.move_cost_duration[current_move.move_cost]
	Overlay.switch_scene(instantiated_scene)
	make_camera_component_tween(absolute_offset)
	make_camera_component_tween()

func make_camera_component_tween(absolute_offset = null):
	var is_zoom = absolute_offset == null
	var original_value = zoom_level if is_zoom else grid_offset
	await create_tween().tween_method(
		func(value):
			if is_zoom: zoom_level = value
			else: grid_offset = value
			update_board(),
		original_value, full_zoom if is_zoom else absolute_offset, trick_transition_duration
	).set_ease(Tween.EASE_IN_OUT).finished

func push_piece():
	selected_tile = GameState.active_game.trick_move_origin
	hovered_tile = GameState.active_game.trick_move_destination
	play_move(true)

const moves_until_power_up_regen_start = 2

func handle_power_up_regeneration():
	for power_up_spawn_pos in GameState.active_game.power_up_piece_info.keys():
		var holder_info = GameState.active_game.power_up_piece_info[power_up_spawn_pos]
		var has_holder_moved = holder_info.piece_pos == selected_tile
		var was_holder_captured = holder_info.piece_pos == hovered_tile
		if was_holder_captured:
			start_power_up_regeneration_counter(power_up_spawn_pos)
			continue
		if not has_holder_moved: continue
		
		holder_info.piece_pos = hovered_tile
		holder_info.moves_since_gather += 1
		var holder_move_count = holder_info.moves_since_gather
		if holder_move_count >= moves_until_power_up_regen_start:
			start_power_up_regeneration_counter(power_up_spawn_pos)
	
	progress_power_up_regeneration_counters()
	handle_power_up_waiting_for_no_piece_array()

const wait_until_power_up_regeneration = 3

func start_power_up_regeneration_counter(power_up_spawn_pos):
	var power_up_info = GameState.active_game.power_up_piece_info
	power_up_info.erase(power_up_spawn_pos)
	var regeneration_wait_time_dict = GameState.active_game.power_up_regeneration_wait_times
	regeneration_wait_time_dict[power_up_spawn_pos] = wait_until_power_up_regeneration

func progress_power_up_regeneration_counters():
	var regeneration_wait_time_dict: Dictionary = GameState.active_game.power_up_regeneration_wait_times
	for power_up_spawn_pos in regeneration_wait_time_dict.keys():
		var time_until_spawn_allowed = regeneration_wait_time_dict[power_up_spawn_pos] - 1
		regeneration_wait_time_dict[power_up_spawn_pos] = time_until_spawn_allowed
		if time_until_spawn_allowed > 0: continue
		
		regeneration_wait_time_dict.erase(power_up_spawn_pos)
		var is_piece_on_spawn = power_up_spawn_pos in GameState.active_game.piece_locations.keys()
		if is_piece_on_spawn:
			GameState.active_game.power_ups_waiting_for_no_piece.append(power_up_spawn_pos)
			continue
		
		GameState.active_game.generate_power_up(power_up_spawn_pos, power_ups)
		

func handle_power_up_waiting_for_no_piece_array():
	var waiting_for_no_piece_arr = GameState.active_game.power_ups_waiting_for_no_piece
	var duplicated_arr = waiting_for_no_piece_arr.duplicate()
	var piece_locations = GameState.active_game.piece_locations
	for power_up_spawn_pos in duplicated_arr:
		var is_piece_on_spawn = power_up_spawn_pos in piece_locations.keys()
		if is_piece_on_spawn: continue
		waiting_for_no_piece_arr.erase(power_up_spawn_pos)
		GameState.active_game.generate_power_up(power_up_spawn_pos, power_ups)

var point_sources : Array[PointSource]

enum PointSource {
	Unknown,
	CorrectAnswer,
	CompletedMinigame,
	ObtaintedPowerUp,
	CapturedSword,
	KilledPiece,
	ObtaintedFlag,
	ReturnedFlag
}

const point_sources_values: Dictionary[PointSource, int] = {
	PointSource.CorrectAnswer: 3,
	PointSource.CompletedMinigame: 6,
	PointSource.ObtaintedPowerUp: 2,
	PointSource.CapturedSword: 5,
	PointSource.KilledPiece: 9,
	PointSource.ObtaintedFlag: 6,
	PointSource.ReturnedFlag: 4
}

func update_points():
	var obtainted_point_value = 0
	for point_source: PointSource in point_sources:
		var source_value = point_sources_values[point_source]
		obtainted_point_value += source_value
		
	var gathered_points_dict = GameState.active_game.team_gathered_points
	var player_color = GameState.active_game.get_inverted_turn()
	var new_point_count = gathered_points_dict.get(player_color, 0) + obtainted_point_value
	gathered_points_dict[player_color] = new_point_count
