shader_type canvas_item;

uniform float offset = 0.0;
uniform float arrow_count = 2.0;
uniform bool reversed_progress = false;
uniform vec4 arrow_modulate;

void fragment() {
	float used_time = mod(offset, 1.0);
	if (reversed_progress) used_time *= -1.0;
	float used_uv_x = UV.x * arrow_count;
	float offset_uv_x = mod(used_uv_x - used_time, 1.0);
	vec2 offset_uv = vec2(offset_uv_x, UV.y);
	COLOR = texture(TEXTURE, offset_uv);
	COLOR += arrow_modulate;
}