class_name Move
extends Resource

enum MoveCost {
	Unknown,
	Regular,
	Medium,
	Fast,
	FastTrick
}

const move_cost_duration: Dictionary[MoveCost, int] = {
	MoveCost.Regular: 30, MoveCost.Medium: 25, MoveCost.Fast: 20, MoveCost.FastTrick: 15
}

var move_cost := MoveCost.Unknown
var trick_move := false
var attribute := Attribute.None
var moved_piece: Piece

enum Attribute {
	None,
	SwordRevive,
	PieceFreeze
}

static func ctor(cost: MoveCost, is_trick := false, attr := Attribute.None) -> Move:
	var instance = Move.new()
	instance.move_cost = cost
	instance.trick_move = is_trick or cost == MoveCost.FastTrick
	instance.attribute = attr
	return instance
