@tool
extends Sprite2D

enum UniformType {
	Offset,
	ArrowCount,
	ReversedProgress,
	ArrowModulate
}

func uniform_as_str(uniform: UniformType) -> String: return UniformType.keys()[uniform].to_snake_case()
func set_uniform(parameter: UniformType, value): material.set_shader_parameter(uniform_as_str(parameter), value)

@export var time_scale: float = 1.0
@export var going_left := false
@export var arrow_modulate: Color

var current_offset: float = 0
var used_scale: Vector2

func _ready():
	material = UID.moving_arrows_shader.duplicate()

func _process(delta: float):
	current_offset += delta * time_scale
	set_uniform(UniformType.Offset, current_offset)
	var aspect_ratio = used_scale.x / used_scale.y
	set_uniform(UniformType.ArrowCount, aspect_ratio)
	set_uniform(UniformType.ReversedProgress, going_left)
	set_uniform(UniformType.ArrowModulate, Color(arrow_modulate, 0))
	texture = UID.conveyor_arrow_left if going_left else UID.conveyor_arrow_right
