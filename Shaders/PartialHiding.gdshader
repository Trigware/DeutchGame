shader_type canvas_item;

uniform float visibility_value = 0;

const float default_y_center = 0.75;

void fragment() {
	float y_uv = UV.y;
	float y_center = default_y_center;
	float dist_from_y = abs(y_center - y_uv);
	bool pixel_visible = dist_from_y < visibility_value / 4.0;
	if (!pixel_visible) COLOR.a = 0.0;
}