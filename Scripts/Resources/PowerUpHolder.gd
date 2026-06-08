class_name PowerUpHolder
extends Resource

var piece_pos: Vector2i
var moves_since_gather: int

static func ctor(current_pos) -> PowerUpHolder:
	var instance = PowerUpHolder.new()
	instance.piece_pos = current_pos
	return instance
