class_name Effect
extends Resource

enum StatusEffect {
	Unknown,
	Fainted,
	Protected,
	Speed,
	Frozen,
	RedFlag,
	BlueFlag
}

const status_effect_atlas_coord : Dictionary[StatusEffect, Vector2i] = {
	StatusEffect.Fainted: Vector2i.ZERO,
	StatusEffect.Protected: Vector2i(1, 0),
	StatusEffect.RedFlag: Vector2i(2, 0),
	StatusEffect.Speed: Vector2i(0, 1),
	StatusEffect.Frozen: Vector2i(1, 1),
	StatusEffect.BlueFlag: Vector2i(2, 1)
}

func get_atlas() -> Vector2i:
	return status_effect_atlas_coord[effect_type]

var effect_type := StatusEffect.Unknown
var remaining_duration: int
var duration_node: EffectDuration
var linked_piece: Piece

static func ctor(effect: StatusEffect, piece: Piece) -> Effect:
	var instance := Effect.new()
	instance.effect_type = effect
	instance.linked_piece = piece
	return instance
