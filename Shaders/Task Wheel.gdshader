shader_type canvas_item;

const int max_color_count = 8;

uniform int amount_of_segments;
uniform float wheel_rotation;
uniform vec4[max_color_count] segment_colors;
uniform vec2 texture_size;
uniform float seperator_size = 8;
uniform vec4 seperator_tint = vec4(1);
uniform float inner_radius;
uniform vec4 inner_tint;
uniform float minimal_seperator_length;
uniform float rotation_shift;

const float circle_radius = 50.0;

float dist(vec2 a, vec2 b) {
	float x_dist = abs(a.x-b.x);
	float y_dist = abs(a.y-b.y);
	return sqrt(x_dist * x_dist + y_dist * y_dist);
}

const float epsilon = 0.001;
bool float_equal(float a, float b) {
	return abs(b - a) <= epsilon;
}

void fragment() {
	vec2 circle_center = vec2(circle_radius/texture_size.x, circle_radius/texture_size.y);
	vec2 current_pixel = floor(UV / (1.0 / texture_size));
	vec2 used_pixel_coord = current_pixel + vec2(0.5, 0.5);
	vec2 used_uv = used_pixel_coord / texture_size;
	
	vec2 dist_from_center = used_uv - circle_center;
	float point_angle = atan(dist_from_center.y, dist_from_center.x);
	float used_wheel_rotation = wheel_rotation;
	float rotation_in_rad = used_wheel_rotation * TAU;
	float offseted_angle = point_angle - rotation_in_rad;
	
	float segment_length = TAU / float(amount_of_segments);
	float expected_seperator_size = segment_length * seperator_size;
	float seperator_size_exceeded = expected_seperator_size / (TAU * minimal_seperator_length);
	float used_seperator_size = seperator_size / max(1, seperator_size_exceeded);
	if (amount_of_segments < 2) used_seperator_size = 0.0;
	
	float seperator_length_rad = segment_length * float(used_seperator_size);
	float angle_in_segment = mod(offseted_angle, segment_length);
	float angle_dist_to_edge = min(angle_in_segment, segment_length - angle_in_segment);
	
	bool is_seperator = angle_dist_to_edge <= seperator_length_rad / 2.0 && amount_of_segments > 0;
	int segment_index = int(floor(offseted_angle / segment_length));
	float non_negative_index = mod(float(segment_index), float(amount_of_segments));
	
	int cyclic_index = int(mod(non_negative_index, float(max_color_count)));
	int used_index = cyclic_index;
	int completed_colors_set_count = amount_of_segments / max_color_count;
	int first_incomplete_set_index = max_color_count * completed_colors_set_count;
	bool has_almost_complete_set = mod(float(amount_of_segments), float(max_color_count)) == float(max_color_count) - 1.0;
	bool use_reverse_colors = non_negative_index >= float(first_incomplete_set_index) && completed_colors_set_count > 0 && !has_almost_complete_set;
	bool in_inner = dist(circle_center, used_uv) <= inner_radius / 2.0;
	
	if (use_reverse_colors) used_index = max_color_count - cyclic_index - 2;
	vec4 used_tint = segment_colors[used_index];
	if (amount_of_segments <= 0) used_tint = vec4(1);
	if (is_seperator) used_tint = seperator_tint;
	if (in_inner) used_tint = inner_tint;
	COLOR *= used_tint;
}