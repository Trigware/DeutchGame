class_name EffectDuration
extends Label

const status_tile_size := 16.0
const pos_offset = Vector2i(1, -3)

const initial_durations: Dictionary[Effect.StatusEffect, int] = {
	Effect.StatusEffect.Fainted: 1
}

var linked_effect: Effect = null

func setup(coords: Vector2i, status_effect: Effect, parent: Node):
	var duration_pos: Vector2i = status_tile_size * coords
	duration_pos += pos_offset
	position = duration_pos
	status_effect.duration_node = self
	var init_duration = 0
	var duration_defined = status_effect.effect_type in initial_durations
	if duration_defined: init_duration = initial_durations[status_effect.effect_type]
	status_effect.remaining_duration = init_duration
	linked_effect = status_effect
	update_text_node()
	parent.add_child(self)

func progress_effect_timer():
	var can_progress = linked_effect.linked_piece.team_relation != GridState.active_game.player_turn
	if not can_progress: return
	linked_effect.remaining_duration = max(linked_effect.remaining_duration - 1, 0)
	update_text_node()

func update_text_node():
	text = str(linked_effect.remaining_duration)
	if linked_effect.remaining_duration == 0: text = ""
