shader_type canvas_item;

uniform float tile_count = 2.0;

void fragment() {
	float used_x = mod(UV.x * tile_count, 1.0);
	vec2 used_uv = vec2(used_x, UV.y);
	COLOR = texture(TEXTURE, used_uv);
}