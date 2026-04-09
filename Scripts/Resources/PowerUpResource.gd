class_name PowerUp
extends Resource

var kind := GridState.PowerUpType.None
var amount := 0

static func ctor(power_up_type: GridState.PowerUpType, count: int):
	var instance = PowerUp.new()
	instance.kind = power_up_type
	instance.amount = count
	return instance
