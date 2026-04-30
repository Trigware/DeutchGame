@tool
extends Node2D

@onready var conveyor = $Conveyor
@onready var moving_arrows = $"Moving Arrows"

@export var going_left := false
@export var invert_color := false
@export var arrow_colors : Dictionary[bool, Color] = {
	false: Color("660000"),
	true: Color("003f66")
}

func _process(_delta):
	var tile_count = scale.x / scale.y
	conveyor.material.set_shader_parameter("tile_count", tile_count)
	moving_arrows.going_left = going_left
	moving_arrows.used_scale = scale
	
	var used_dir_state = going_left
	if invert_color: used_dir_state = not going_left
	if used_dir_state in arrow_colors:
		moving_arrows.arrow_modulate = arrow_colors[used_dir_state]
