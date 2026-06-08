class_name EffectDuration
extends Label

const status_tile_size := 16.0
const pos_offset = Vector2i(1, -3)

const initial_durations: Dictionary[Effect.StatusEffect, int] = {
	Effect.StatusEffect.Fainted: 0,
	Effect.StatusEffect.Speed: 2,
	Effect.StatusEffect.Protected: 3,
	Effect.StatusEffect.Slowness: 2,
	Effect.StatusEffect.Frozen: 4
}

var linked_effect: Effect = null

func setup(coords: Vector2i, status_effect: Effect, parent: Node):
	var duration_pos: Vector2i = status_tile_size * coords
	duration_pos += pos_offset
	position = duration_pos
	status_effect.duration_node = self
	
	var init_duration = status_effect.remaining_duration
	var duration_defined = status_effect.effect_type in initial_durations
	if duration_defined and not status_effect.effect_initialized: init_duration = initial_durations[status_effect.effect_type]
	status_effect.effect_initialized = true
	status_effect.remaining_duration = init_duration
	
	linked_effect = status_effect
	update_text_node()
	parent.add_child(self)

func progress_effect_timer():
	var can_progress = linked_effect.linked_piece.team_relation == GameState.active_game.player_turn
	if not can_progress: return
	linked_effect.remaining_duration = max(linked_effect.remaining_duration - 1, 0)
	update_text_node()

func update_text_node():
	text = str(linked_effect.remaining_duration)
	var auto_non_deletable_effect = linked_effect.effect_type == Effect.StatusEffect.Fainted or\
		not linked_effect.effect_type in initial_durations.keys()
	
	var out_of_time = linked_effect.remaining_duration == 0
	if out_of_time: text = ""
	if not (out_of_time and not auto_non_deletable_effect): return
	
	var piece: Piece = linked_effect.linked_piece
	piece.remove_effect(linked_effect.effect_type)
	var piece_locations_index = GameState.active_game.piece_locations.values().find(piece)
	var piece_pos = GameState.active_game.piece_locations.keys()[piece_locations_index]
	GameState.active_game.grid_tiles.draw_piece_to_board(piece, piece_pos)
