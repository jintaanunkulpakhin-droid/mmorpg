// A small health bar that always faces the camera and draws on top of everything.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, shadows_disabled;

uniform float value : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.9, 0.2, 0.2, 1.0);

void vertex() {
	// Billboard: keep the position, but turn to face the camera.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 edge = step(vec2(0.03, 0.15), UV) * step(UV, vec2(0.97, 0.85));
	float inside = edge.x * edge.y;
	vec3 col = vec3(0.05);
	if (inside > 0.5) {
		col = UV.x < value ? fill_color.rgb : vec3(0.18, 0.12, 0.12);
	}
	ALBEDO = col;
}
