// Thin coloured outline drawn around characters ("inverted hull").
// The model is drawn a second time, pushed out a little and inside-out.
// The push happens in screen space, so the line stays the same thickness
// at every zoom level.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

// Warm dark brown instead of black, as the style guide asks.
uniform vec4 outline_color : source_color = vec4(0.353, 0.227, 0.227, 1.0);
uniform float width_px = 1.6;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 clip_normal = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	if (length(clip_normal) > 0.0001) {
		clip.xy += normalize(clip_normal) / VIEWPORT_SIZE * width_px * 2.0 * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
