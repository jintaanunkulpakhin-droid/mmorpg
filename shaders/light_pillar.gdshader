// A column of light for level ups and fire skills. Put it on an open cylinder.
// It is bright at the bottom and fades out towards the top.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float fade = 1.0;
uniform float scroll = 0.0;

void fragment() {
	float up = 1.0 - UV.y;  // 0 at the bottom, 1 at the top
	float streaks = 0.65 + 0.35 * sin(UV.x * 50.0 + scroll * 4.0) * sin(UV.x * 17.0 - scroll * 2.0);
	float a = pow(1.0 - up, 1.6) * streaks;
	ALBEDO = color.rgb * a * 2.0;
	ALPHA = clamp(a, 0.0, 1.0) * fade;
}
