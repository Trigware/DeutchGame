class_name PlayerPowerUp
extends Resource

var power_ups: Dictionary[GridState.PowerUpType, PowerUp] = {}

static func ctor(power_up_arr: Array[PowerUp]):
	var instance = PlayerPowerUp.new()
	for power_up: PowerUp in power_up_arr:
		instance.power_ups[power_up.kind] = power_up
	return instance
