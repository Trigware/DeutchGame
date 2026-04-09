shader_type canvas_item;

uniform vec2 pixel_count;
uniform vec2 texture_size;
uniform vec2 texture_scale;
uniform float diagonal_lines;
uniform float gap_size;
uniform float pattern_repeated;
uniform vec4 line_color;
uniform vec4 gap_color;

const vec2 pixel_offset = vec2(0.5), center = vec2(0.5);
const vec2 comparison_pivot = vec2(0.0);

float get_dist(vec2 a, vec2 b) {
	float x_dist = a.x - b.x, y_dist = b.x - b.y;
	return sqrt(x_dist*x_dist + y_dist*y_dist);
}

void fragment() {
	vec2 pixel_size = 1.0 / pixel_count;
	vec2 used_uv = UV * texture_size / texture_scale;
	vec2 pixel_coord = floor(used_uv / pixel_size) + pixel_offset;
	vec2 pixel_uv = pixel_coord / pixel_count;
	
	vec2 rotated_uv = vec2(pixel_uv.y, pixel_uv.x);
	vec2 midpoint = (pixel_uv + rotated_uv) / 2.0;
	float dist = get_dist(midpoint, comparison_pivot) - pattern_repeated;
	
	float sector_length = 1.0 / diagonal_lines;
	float sector_portion = fract(dist / sector_length);
	float half_gap = gap_size / 2.0;
	bool in_gap = (sector_portion <= half_gap || sector_portion >= 1.0 - half_gap) && gap_size != 0.0;
	
	COLOR = in_gap ? gap_color : line_color;
}