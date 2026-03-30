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
	effect.duration_node.queue_free()
	effect.duration_node = null
	status_effects.erase(effect_type)

func add_effect(effect: Effect.StatusEffect):
	status_effects[effect] = Effect.ctor(effect, self)

func is_effect_over(effect: Effect.StatusEffect):
	var has_effect = effect in status_effects
	if not has_effect: return false
	return status_effects[effect].remaining_duration == 0

func has_flag() -> bool:
	return has_status_effect(Effect.StatusEffect.RedFlag) or has_status_effect(Effect.StatusEffect.BlueFlag)
