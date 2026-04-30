class_name Piece
extends Resource

@export var kind := GridState.PieceType.Unknown
@export var team_relation: SpecialTile.TeamRelation
var respawn_pos: Vector2i
var status_effects: Dictionary[Effect.StatusEffect, Effect]

const red_piece = 1
const blue_piece = 2

func get_atlas() -> Vector2i:
	var y_coord = red_piece if team_relation == SpecialTile.TeamRelation.Red else blue_piece
	return Vector2(GridState.piece_atlas_coords_x[kind], y_coord)

static func ctor(piece_kind: GridState.PieceType, team: SpecialTile.TeamRelation):
	var instance = Piece.new()
	instance.kind = piece_kind
	instance.team_relation = team
	return instance

func has_status_effect(compared_effect: Effect.StatusEffect) -> bool:
	return compared_effect in status_effects

func remove_all_effects():
	for effect: Effect.StatusEffect in status_effects.keys():
		remove_effect(effect)

func override_effects(effect: Effect.StatusEffect):
	remove_all_effects()
	add_effect(effect)

func remove_effect(effect_type: Effect.StatusEffect):
	var effect: Effect = status_effects[effect_type]
	if effect.duration_node != null:
		effect.duration_node.queue_free()
	effect.duration_node = null
	status_effects.erase(effect_type)

func add_effect(effect: Effect.StatusEffect):
	var adding_slowness = effect == Effect.StatusEffect.Slowness
	var adding_speed = effect == Effect.StatusEffect.Speed
	var has_slowness = has_status_effect(Effect.StatusEffect.Slowness)
	var has_speed = has_status_effect(Effect.StatusEffect.Speed)
	if adding_slowness and has_speed: remove_effect(Effect.StatusEffect.Speed)
	if adding_speed and has_slowness: remove_effect(Effect.StatusEffect.Slowness)
	var already_has_effect = has_status_effect(effect)
	var effect_instance: Effect = Effect.ctor(effect, self)
	if already_has_effect:
		effect_instance = status_effects[effect]
		var init_duration = 0
		if effect in EffectDuration.initial_durations: init_duration = EffectDuration.initial_durations[effect]
		effect_instance.remaining_duration += init_duration
	status_effects[effect] = effect_instance

func is_effect_over(effect: Effect.StatusEffect):
	var has_effect = effect in status_effects
	if not has_effect: return false
	return status_effects[effect].remaining_duration == 0

func has_flag() -> bool:
	return has_status_effect(Effect.StatusEffect.RedFlag) or has_status_effect(Effect.StatusEffect.BlueFlag)

func flag_kind() -> SpecialTile.TeamRelation:
	if not has_flag(): return SpecialTile.TeamRelation.Other
	return SpecialTile.TeamRelation.Blue if team_relation == SpecialTile.TeamRelation.Red\
		else SpecialTile.TeamRelation.Red

func belongs_to_playing(): return team_relation == GridState.active_game.player_turn

const flag_effect_dict : Dictionary[SpecialTile.TeamRelation, Effect.StatusEffect] = {
	SpecialTile.TeamRelation.Red: Effect.StatusEffect.RedFlag,
	SpecialTile.TeamRelation.Blue: Effect.StatusEffect.BlueFlag
}

func remove_flag():
	var flag_color = flag_kind()
	var flag_effect = flag_effect_dict[flag_color]
	remove_effect(flag_effect)
