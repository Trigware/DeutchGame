@tool
extends ColorRect

enum UniformType {
	PixelCount,
	TextureSize,
	TextureScale,
	DiagonalLines,
	GapSize,
	PatternRepeated,
	LineColor,
	GapColor,
	RotationRepeated
}

@export var diagonal_lines: float:
	set(value): diagonal_lines = value; set_uniform(UniformType.DiagonalLines, value)
@export_range(0, 1) var gap_size: float:
	set(value): gap_size = value; set_uniform(UniformType.GapSize, value)
var pattern_repeated: float = 0:
	set(value): pattern_repeated = value; set_uniform(UniformType.PatternRepeated, value)
@export var line_color: Color
@export var pixel_count: Vector2i:
	set(value): pixel_count = value; set_uniform(UniformType.PixelCount, value)
@export var texture_scale: Vector2
@export var rotation_repeated: float:
	set(value): rotation_repeated = value; set_uniform(UniformType.RotationRepeated, value)
@export var value_offset: float
@export var pattern_speed: float

func uniform_as_str(uniform: UniformType) -> String: return UniformType.keys()[uniform].to_snake_case()
func set_uniform(parameter: UniformType, value): material.set_shader_parameter(uniform_as_str(parameter), value)

const default_texture_size = Vector2(40, 40)

func _ready():
	init_gap_size = gap_size

func _process(delta: float):
	set_uniform(UniformType.TextureSize, size / default_texture_size)
	set_uniform(UniformType.TextureScale, texture_scale / scale)
	set_colors()
	position = -size * scale / 2.0 + size / 2.0
	pattern_repeated += delta * pattern_speed

func set_colors():
	set_uniform(UniformType.LineColor, line_color)
	var gap_color = line_color
	gap_color.v -= value_offset;
	set_uniform(UniformType.GapColor, gap_color)

const color_change_half_step_duration = 0.85
const half_step_gap_size = 1.0
var init_gap_size: float

func change_color(new_color: Color):
	var half_step_color = line_color
	half_step_color.s = 0
	create_tween().tween_property(self, "line_color", half_step_color, color_change_half_step_duration)
	await create_tween().tween_property(self, "gap_size", half_step_gap_size, color_change_half_step_duration).set_ease(Tween.EASE_IN_OUT).finished
	create_tween().tween_property(self, "line_color", new_color, color_change_half_step_duration)
	create_tween().tween_property(self, "gap_size", init_gap_size, color_change_half_step_duration).set_ease(Tween.EASE_IN_OUT)
