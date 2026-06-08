extends CanvasLayer

var item_power_up_slots: Array[Node2D] = []
var team_name_containers: Dictionary[SpecialTile.TeamRelation, TeamNameContainer] = {}

@onready var dragged_sprite = $Dragged
@onready var tiles = $"../Tiles"
@onready var board = $".."
@onready var special_tile_map = tiles.get_node("Special Tiles")

func _ready(): setup()
func setup():
	var last_power_up = GridState.PowerUpType.values()[GridState.PowerUpType.size()-1]+1
	for i in range(1, last_power_up):
		for team: SpecialTile.TeamRelation in [SpecialTile.TeamRelation.Red, SpecialTile.TeamRelation.Blue]:
			create_item_slot(team, i, last_power_up)
	for team: SpecialTile.TeamRelation in SpecialTile.TeamRelation.values():
		create_team_container(team)

func create_item_slot(team: SpecialTile.TeamRelation, power_up: SpecialTile.TeamRelation, last_power_up: GridState.PowerUpType):
	var slot_instance = UID.item_slot.instantiate()
	slot_instance.setup(self, item_power_up_slots, power_up, team, last_power_up)

func create_team_container(team: SpecialTile.TeamRelation):
	if team == SpecialTile.TeamRelation.Other or board.is_playing_tutorial: return
	var name_container: TeamNameContainer = UID.name_container.instantiate()
	team_name_containers[team] = name_container
	add_child(name_container)
	name_container.set_team_name(team)

const hovered_slot_modulate = Color(0xfffc96ff)
var selected_power_up: GridState.PowerUpType
var selected_power_up_team := SpecialTile.TeamRelation.Other
var current_selected_power_up: GridState.PowerUpType
var item_slot_scale: Vector2
var dragging_power_up := false

func _process(_delta):
	check_for_selected_slots()
	handle_item_dragging()

func check_for_selected_slots():
	selected_power_up = GridState.PowerUpType.None
	var slots_x: Dictionary[SpecialTile.TeamRelation, float] = {}
	var unoccupied_height: float
	var actual_slot_combined_height: float
	
	for item_slot: ItemSlot in item_power_up_slots:
		item_slot_scale = item_slot.update_slot()
		unoccupied_height = item_slot.unoccupied_height
		actual_slot_combined_height = item_slot.actual_slot_combined_height
		slots_x[item_slot.item_slot_team] = item_slot.position.x
		var hovering_over_slot = item_slot.is_mouse_inside_slot()
		var item_belongs_to_current_team = item_slot.item_slot_team == GameState.active_game.player_turn
		var has_no_item_of_type = item_slot.get_item_count() == 0
		
		var slot_modulate = Color.WHITE
		var is_interactable = hovering_over_slot and item_belongs_to_current_team and not has_no_item_of_type
		if not has_no_item_of_type: slot_modulate = GridState.team_modulate[item_slot.item_slot_team]
		if is_interactable: slot_modulate = hovered_slot_modulate
		item_slot.main_sprite.modulate = slot_modulate
		if not is_interactable: continue
		
		if dragging_power_up: continue
		selected_power_up = item_slot.power_up_kind
		selected_power_up_team = item_slot.item_slot_team
	
	for team_name_container: TeamNameContainer in team_name_containers.values():
		team_name_container.update_container(slots_x, item_slot_scale, unoccupied_height, actual_slot_combined_height)

var prev_frame_highlight_visible := false
var latest_selected_power_up := GridState.PowerUpType.None
var prev_frame_was_dragging := false

func handle_item_dragging():
	var is_dragging = Input.is_action_pressed("dragging_slot")
	var is_hovering_above_slot = selected_power_up != GridState.PowerUpType.None
	if is_dragging and is_hovering_above_slot: dragging_power_up = true
	if not is_dragging and not is_hovering_above_slot: dragging_power_up = false
	var is_highlight_visible = dragging_power_up or is_hovering_above_slot
	if selected_power_up != GridState.PowerUpType.None:
		latest_selected_power_up = selected_power_up
	
	if is_highlight_visible and not prev_frame_highlight_visible: start_affected_tiles_highlight()
	if not is_highlight_visible and prev_frame_highlight_visible: stopped_affected_tiles_highlight()
	
	dragged_sprite.visible = dragging_power_up
	prev_frame_highlight_visible = is_highlight_visible
	prev_frame_was_dragging = is_dragging
	if not dragging_power_up: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	dragged_sprite.position = mouse_pos
	if selected_power_up > 0:
		dragged_sprite.frame_coords.x = selected_power_up - 1
	dragged_sprite.scale = item_slot_scale

var highlighted_tiles: Array[Vector2i]

const power_up_effect_equivalent: Dictionary[GridState.PowerUpType, Effect.StatusEffect] = {
	GridState.PowerUpType.SpeedBoost: Effect.StatusEffect.Speed,
	GridState.PowerUpType.Shield: Effect.StatusEffect.Protected,
	GridState.PowerUpType.WizardFreeze: Effect.StatusEffect.Frozen,
	GridState.PowerUpType.OpponentSlowness: Effect.StatusEffect.Slowness
}

func start_affected_tiles_highlight():
	update_highlighted_tiles()
	for tile_coord: Vector2i in highlighted_tiles: tiles.update_board_tile(tile_coord, tiles.TileType.Move)

func stopped_affected_tiles_highlight():
	for tile_coord: Vector2i in highlighted_tiles: tiles.reset_board_tile(tile_coord)
	var hovered_coord = tiles.get_hovered_tile()
	if not hovered_coord in highlighted_tiles or not prev_frame_was_dragging: return
	
	Audio.play_sound(UID.power_up_sfx)
	GameState.active_game.decrement_power_up(latest_selected_power_up)
	var used_tricky_item = latest_selected_power_up == GridState.PowerUpType.TrickyItem
	if used_tricky_item:
		handle_trick_question_placement(hovered_coord)
		return
	handle_regular_power_up_placement(hovered_coord)

func handle_regular_power_up_placement(hovered_coord: Vector2i):
	var piece: Piece = GameState.active_game.piece_locations[hovered_coord]
	var status_effect = power_up_effect_equivalent[latest_selected_power_up]
	piece.add_effect(status_effect)
	tiles.draw_piece_to_board(piece, hovered_coord)

func handle_trick_question_placement(hovered_coord: Vector2i):
	var trick_color = GameState.active_game.get_inverted_turn()
	var trick_question = SpecialTile.trick(trick_color)
	GameState.active_game.special_tiles[hovered_coord] = trick_question
	var trick_atlas = trick_question.get_atlas()
	special_tile_map.set_cell(hovered_coord, 1, trick_atlas)

const current_team_power_ups : Array[GridState.PowerUpType] = [GridState.PowerUpType.SpeedBoost, GridState.PowerUpType.Shield]

func update_highlighted_tiles():
	if selected_power_up in current_team_power_ups: update_affected_pieces_of_team(GameState.active_game.player_turn)
	match selected_power_up:
		GridState.PowerUpType.OpponentSlowness:
			var inverted_turn = GameState.active_game.get_inverted_turn()
			update_affected_pieces_of_team(inverted_turn)
		GridState.PowerUpType.WizardFreeze: update_affected_wizard_pieces()
		GridState.PowerUpType.TrickyItem: update_tiles_with_tricky_item_positions()

func update_affected_pieces_of_team(team_relation: SpecialTile.TeamRelation):
	highlighted_tiles = []
	for tile_coord: Vector2i in GameState.active_game.piece_locations.keys():
		var piece: Piece = GameState.active_game.piece_locations[tile_coord]
		var piece_is_fainted = piece.has_status_effect(Effect.StatusEffect.Fainted)
		if piece.team_relation != team_relation or piece.kind == GridState.PieceType.Horse or piece_is_fainted: continue
		highlighted_tiles.append(tile_coord)

func update_affected_wizard_pieces():
	highlighted_tiles = []
	for tile_coord: Vector2i in GameState.active_game.piece_locations.keys():
		var piece: Piece = GameState.active_game.piece_locations[tile_coord]
		if piece.belongs_to_playing() or piece.kind != GridState.PieceType.Wizard: continue
		highlighted_tiles.append(tile_coord)

func update_tiles_with_tricky_item_positions():
	highlighted_tiles = []
	for tile_coord: Vector2i in GameState.active_game.piece_locations.keys():
		var piece: Piece = GameState.active_game.piece_locations[tile_coord]
		var is_frozen = piece.has_status_effect(Effect.StatusEffect.Frozen)
		var is_fainted = piece.has_status_effect(Effect.StatusEffect.Fainted)
		var is_not_sword = piece.kind != GridState.PieceType.Sword
		var cannot_place = not piece.belongs_to_playing() or is_not_sword or is_frozen or is_fainted
		if cannot_place: continue
		
		var sword_moves = board.get_possible_sword_moves(piece, tile_coord)
		for move_dest: Vector2i in sword_moves.keys():
			var move: Move = sword_moves[move_dest]
			var expensive_move = move.move_cost == Move.MoveCost.FastTrick
			var place_has_piece = move_dest in GameState.active_game.piece_locations
			var place_has_special_tile = move_dest in GameState.active_game.special_tiles
			var place_invalid = expensive_move or place_has_piece or place_has_special_tile
			if place_invalid: continue
			highlighted_tiles.append(move_dest)
