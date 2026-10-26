// Grey-brown mine floor drawn with noise, so there is no texture file:
// big soft patches of colour, darker cracks between flagstones and small grit.
shader_type spatial;

#include "res://shaders/toon_light.gdshaderinc"

uniform vec4 stone_light : source_color = vec4(0.52, 0.48, 0.43, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.36, 0.33, 0.30, 1.0);
uniform vec4 crack_color : source_color = vec4(0.2, 0.18, 0.17, 1.0);
uniform float stone_size = 2.2;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

// Distance to the nearest edge between irregular flagstones (a simple Voronoi).
float stone_edge(vec2 p) {
	vec2 cell = floor(p);
	float first = 8.0;
	float second = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = cell + vec2(float(x), float(y));
			vec2 point = c + vec2(hash(c), hash(c + 17.0)) * 0.8 + 0.1;
			float d = length(p - point);
			if (d < first) {
				second = first;
				first = d;
			} else if (d < second) {
				second = d;
			}
		}
	}
	return second - first;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz / stone_size;
	float patches = noise(p * 0.35) * 0.6 + noise(p * 1.3) * 0.4;
	vec3 col = mix(stone_dark.rgb, stone_light.rgb, patches);
	col *= 0.9 + 0.2 * noise(world_pos.xz * 9.0);  // grit
	float edge = smoothstep(0.0, 0.045, stone_edge(p));
	col = mix(mix(col, crack_color.rgb, 0.55), col, edge);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
