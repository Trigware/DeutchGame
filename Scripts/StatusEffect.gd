class_name Effect
extends Resource

enum StatusEffect {
	Unknown,
	Fainted,
	Protected,
	Speed,
	Frozen,
	RedFlag,
	BlueFlag,
	Slowness
}

func get_atlas() -> Vector2i:
	return Vector2i(effect_type - 1, 0)

var effect_type := StatusEffect.Unknown
var remaining_duration: int
var duration_node: EffectDuration = null
var linked_piece: Piece

const flag_kind : Array[StatusEffect] = [StatusEffect.RedFlag, StatusEffect.BlueFlag]

static func ctor(effect: StatusEffect, piece: Piece) -> Effect:
	var instance := Effect.new()
	instance.effect_type = effect
	instance.linked_piece = piece
	return instance

func is_effect_flag_kind(): return effect_type in flag_kind
