@tool
extends Node

@onready var wheel = $Wheel

@export var number_of_segments: int:
	set(value): number_of_segments = value; set_uniform(UniformType.AmountOfSegments, value)
@export var wheel_rotation: float:
	set(value): wheel_rotation = value; set_uniform(UniformType.WheelRotation, value)
@export var base_wheel_color := Color("d17171ff"):
	set(value): base_wheel_color = value; set_segment_colors()
@export var seperator_size: int:
	set(value): seperator_size = value; set_uniform(UniformType.SeperatorSize, value)
@export var seperator_tint := Color.WHITE
@export_range(0, 1) var inner_radius: float:
	set(value): inner_radius = value; set_uniform(UniformType.InnerRadius, value)
@export var inner_tint: Color

const inner_boundary_value_offset = 0.1

enum UniformType {
	AmountOfSegments,
	WheelRotation,
	SegmentColors,
	TextureSize,
	SeperatorSize,
	SeperatorTint,
	InnerRadius,
	InnerTint,
	InnerBoundary
}

func uniform_as_str(uniform: UniformType) -> String: return UniformType.keys()[uniform].to_snake_case()
func set_uniform(parameter: UniformType, value): wheel.material.set_shader_parameter(uniform_as_str(parameter), value)

const max_color_count = 8

func _process(_delta):
	var texture_size = wheel.texture.get_size()
	set_uniform(UniformType.TextureSize, texture_size)
	set_uniform(UniformType.SeperatorTint, seperator_tint)
	set_uniform(UniformType.InnerTint, inner_tint)
	var inner_bound_color = inner_tint
	inner_bound_color.v += inner_boundary_value_offset
	set_uniform(UniformType.InnerBoundary, inner_bound_color)

func set_segment_colors():
	var segment_colors : Array[Color] = []
	var number_count = min(number_of_segments, max_color_count)
	var segment_hue_shift = 1.0 / number_count
	for i in range(number_count):
		var current_color = base_wheel_color
		current_color.h += segment_hue_shift * i
		segment_colors.append(current_color)
	set_uniform(UniformType.SegmentColors, segment_colors)

func _ready():
	set_segment_colors()
