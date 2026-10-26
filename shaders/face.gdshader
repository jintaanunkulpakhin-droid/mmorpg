// The chibi face. Like ECO-style games, the face is "painted" onto the head
// instead of being modelled: eyes, blush and mouth are drawn here.
// "blink" goes from 1.0 (open) to 0.0 (closed), so blinking is just a number.
shader_type spatial;

#include "res://shaders/toon_light.gdshaderinc"

uniform vec4 skin_color : source_color = vec4(0.984, 0.89, 0.824, 1.0);
uniform vec4 eye_color : source_color = vec4(0.36, 0.55, 0.85, 1.0);
uniform vec4 line_color : source_color = vec4(0.29, 0.196, 0.125, 1.0);
uniform vec4 blush_color : source_color = vec4(0.957, 0.6, 0.67, 1.0);
uniform float blink : hint_range(0.0, 1.0) = 1.0;
uniform float smile : hint_range(0.0, 1.0) = 0.6;

// Face layout, measured on the front of the head (x = left/right, y = up/down).
const float EYE_X = 0.34;
const float EYE_Y = -0.12;
const vec2 EYE_SIZE = vec2(0.15, 0.2);

varying vec3 local_normal;

void vertex() {
	local_normal = NORMAL;
}

vec3 draw_eye(vec3 col, vec2 p, float side) {
	vec2 d = p - vec2(EYE_X * side, EYE_Y);
	if (blink < 0.25) {
		// Closed eye: a little curved line.
		float curve = d.y + 2.2 * d.x * d.x - 0.01;
		if (abs(d.x) < EYE_SIZE.x * 1.05 && abs(curve) < 0.018) {
			col = line_color.rgb;
		}
		return col;
	}
	vec2 e = d / vec2(EYE_SIZE.x, EYE_SIZE.y * blink);
	float r = length(e);
	if (r < 1.0) {
		// Iris: darker at the top, lighter at the bottom, like painted anime eyes.
		float shade = smoothstep(0.7, -0.9, e.y);
		col = mix(eye_color.rgb * 0.45, eye_color.rgb * 1.15, shade);
		// Pupil.
		if (length(e * vec2(1.6, 1.15) - vec2(0.0, 0.05)) < 0.45) {
			col = line_color.rgb * 0.8;
		}
		// Two highlights.
		if (length(e - vec2(-0.32 * side, 0.36)) < 0.27 || length(e - vec2(0.3 * side, -0.42)) < 0.12) {
			col = vec3(1.0);
		}
		// Thick upper lash line.
		if (e.y > 0.62 && r > 0.78) {
			col = line_color.rgb;
		}
	} else if (r < 1.12 && e.y > 0.2) {
		col = line_color.rgb;
	}
	return col;
}

void fragment() {
	vec3 n = normalize(local_normal);
	vec3 col = skin_color.rgb;
	if (n.z > 0.0) {
		vec2 p = n.xy;
		// Blush.
		for (float side = -1.0; side <= 1.0; side += 2.0) {
			vec2 b = (p - vec2(0.5 * side, -0.33)) / vec2(0.13, 0.06);
			if (length(b) < 1.0) {
				col = mix(col, blush_color.rgb, 0.55);
			}
		}
		col = draw_eye(col, p, -1.0);
		col = draw_eye(col, p, 1.0);
		// Small mouth: a curve that bends up when smiling.
		vec2 m = p - vec2(0.0, -0.44);
		float curve = m.y - smile * 3.0 * m.x * m.x;
		if (abs(m.x) < 0.06 && abs(curve) < 0.012) {
			col = line_color.rgb;
		}
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
